require 'spiderfw/controller/spider_controller'
require 'spiderfw/controller/session/memory_session'
require 'spiderfw/controller/session/file_session'

module Spider
    
    class HTTPController < Controller
        include HTTPMixin
        
        
        def initialize(request, response, scene=nil)
            response.status = Spider::HTTP::OK
            response.headers = {
                'Content-Type' => 'text/plain',
                'Connection' => 'close'
            }
            @previous_stdout = $stdout
            Thread.current[:stdout] = response.server_output
            $out = ThreadOut
            $stdout = ThreadOut if Spider.conf.get('http.seize_stdout')
            request.extend(HTTPRequest)
            super(request, response, scene)
        end
        
        def before(action='', *arguments)
            if (@request.env['HTTP_TRANSFER_ENCODING'] == 'Chunked' && !@request.server.supports?(:chunked_request))
                raise HTTPStatus.NOT_IMPLEMENTED
            end
            @request.cookies = Spider::HTTP.parse_query(@request.env['HTTP_COOKIE'], ';')
            @request.session = Session.get(@request.cookies['sid'])
            @response.cookies['sid'] = @request.session.sid
            @response.cookies['sid'].path = '/'
            @request.params = {}
            if (@request.env['QUERY_STRING'])
                @request.params = Spider::HTTP.parse_query(@request.env['QUERY_STRING'])
            end
            if (@request.env['REQUEST_METHOD'] == 'POST' && @request.env['HTTP_CONTENT_TYPE'] && @request.env['HTTP_CONTENT_TYPE'].include?('application/x-www-form-urlencoded'))
                @request.params.merge!(Spider::HTTP.parse_query(@request.read_body))
            end
            if (@request.env['HTTP_ACCEPT_LANGUAGE'])
                lang = @request.env['HTTP_ACCEPT_LANGUAGE'].split(';')[0].split(',')[0]
                GetText.locale = lang
            end
            # @extensions = {
            #     'js' => {:format => :js, :content_type => 'application/javascript'},
            #     'html' => {:format => :html, :content_type => 'text/html', :mixin => HTML},
            #     #'json' => {:format => :json, :content_type => 'text/x-json'}
            #     'json' => {:format => :json, :content_type => 'text/plain'}
            # }

            super
        end
        
        def after(action='', *arguments)
            @request.session.persist if @request.session
            super
        end
        
        def ensure(action='', *arguments)
            dispatch(:ensure, action, *arguments)
            $stdout = @previous_stdout
        end
        
        
        def get_route(path)
            path = path.clone
            path.slice!(0) if path.length > 0 && path[0].chr == "/"
            return Route.new(:path => path, :dest => Spider::SpiderController, :action => path)
        end
        
        def try_rescue(exc)
            if (exc.is_a?(Spider::Controller::NotFound))
                @response.status = Spider::HTTP::NOT_FOUND
                error("Not found: #{exc.path}")
            elsif (exc.is_a?(BadRequest))
                @response.status = Spider::HTTP::BAD_REQUEST
                raise
            elsif (exc.is_a?(Forbidden))
                @response.status = Spider::HTTP::FORBIDDEN
                raise
            else
                @response.status = Spider::HTTP::INTERNAL_SERVER_ERROR
                super
            end
        end
        
        module HTTPRequest
            
            def path
                Spider::ControllerMixins::HTTPMixin.reverse_proxy_mapping(self.env['PATH_INFO'])
            end
            
        end
    
        
        
    end
    
end