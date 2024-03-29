if Spider.conf.get('auth.enable_auth_hub')
    require 'jwt'
end

module Spider; module Auth

    module AuthHelper

        def self.included(mod)
            mod.extend(ClassMethods)
            if mod.respond_to?(:define_annotation)
                mod.define_annotation(:require_user) { |k, m, params| k.require_user(params, :only => m) }
            end
        end
        
        def before(action='', *arguments)
            @request.extend(RequestMethods)
            super
            return if action.index(Spider::Auth.route_url) == 0
            return if respond_to?(:serving_static?) && serving_static?(action)
            self.class.auth_require_users.each do |req|
                klasses, params = req
                klasses = [klasses] unless klasses.is_a?(Array)
                @current_require = params
                unl = params[:unless]
                action_match = true
                if (unl)
                    unl = [unl] unless unl.is_a?(Array)
                    unl.each do |p|
                        action_match = !check_action(action, p)
                        break unless action_match
                    end
                end
                only = params[:only]
                if (only)
                    only = [only] unless only.is_a?(Array)
                    action_match = false
                    only.each do |p|
                        action_match = check_action(action, p)
                        break if action_match
                    end
                end
                next unless action_match
                user = nil
                unauthorized_exception = nil
                requested_class = nil
                users = {} 
                klasses.uniq.each do |klass|
                    user = klass.restore(@request)
                    @request.security[:users] << user if user
                    users[klass] = user
                end
                klasses.each do |klass|
                    requested_class = klass
                    user = users[klass]
                    if user
                        if params[:authentication]
                            user = nil unless user.authenticated?(params[:authentication])
                        elsif (params[:check])
                            begin
                                c = params[:check].call(user)
                                user = nil unless c == true
                                raise Unauthorized.new(c, requested_class) if c.is_a?(String)
                                break
                            rescue => exc
                                user = nil
                                unauthorized_exception = exc
                            end
                        else
                            break
                        end
                    end
                end
                #questo rimanda a fare login
                unless user
                    msg = Spider::GetText.in_domain('spider_auth'){ _("Please login first") }
                    kl = unauthorized_exception ? unauthorized_exception : Unauthorized
                    raise kl.new(msg, requested_class)
                end
                @request.user = user
            end
            
        end
        
        def get_correct_action(request)
            redirect_action = request.action || request.env['REQUEST_URI']
            redirect_param = nil
            if request.user.nil?
                redirect_param = request.action || request.env['REQUEST_URI']
            elsif request.user.is_a?(::Portal::Amministratore)
                #lo mando su /admin
                redirect_param = "/admin"
            elsif !defined?(::Cms).nil? && request.user.is_a?(::Cms::Administrator)
                # admin/cms ?
                redirect_param = "/admin/cms"
            else #superuser
                redirect_param = request.action || request.env['REQUEST_URI']
            end
            @request.session.flash['admin_servizi_non_abilitato'] = "non_abilitato" if redirect_action != redirect_param
            redirect_param
                    
        end

        def try_rescue(exc)
            if (exc.is_a?(Unauthorized))
                conf = Spider.conf.get('auth.enable_auth_hub')
                if conf
                    #controllo se ho un jwt, se sono un admin, 
                    #se nel jwt ho auth del tipo aad allora mostro la email nel messaggio, 
                    #altrimenti nome e cognome o mail se vuoti

                    #NON FA REDIRECT DIRETTO MA PASSA SEMPRE PER PAGINA CON SCELTA TIPOLOGIA ACCESSO SU AUTH HUB
                    # str_redirect = "?&redirect=#{@request.action}" unless @request.action.blank? 
                    # payload = {
                    #     iss: 'soluzionipa.it',
                    #     auth: 'aad',
                    #     ub: Spider::Auth::LoginController.http_s_url+"/do_login#{str_redirect}",
                    #     idc: 'id_di_cosa', #id cliente...
                    #     ext_session_id: @request.session.sid
                    # }
                    # token = JWT.encode payload, "6rg1e8r6t1bv8rt1r7y7b86d8fsw8fe6bg1t61v8vsdfs8erer6c18168", 'HS256'
                    # redir_url = Spider.conf.get("auth.redirect_url_auth_hub")+"/sign_in?jwt=#{token}"
                    redirect_param = get_correct_action(@request)
                    unless @request.params['jwt'].blank?
                        #Spider.logger.error "\n\n Sto facendo il REDIRECT 1 \n\n"
                        redir_url = Spider::Auth::LoginController.http_s_url('do_login?jwt='+@request.params['jwt']+"&rdr=#{redirect_param}")
                    else
                        #pagina di login con i due link per le due modalita' di accesso
                        #Spider.logger.error "\n\n Sto facendo il REDIRECT 2 \n\n"
                        redir_url = Spider::Auth::LoginController.http_s_url+"?rdr=#{redirect_param}"
                    end
                else
                    base = (@current_require && @current_require[:redirect]) ? @current_require[:redirect] : Spider::Auth.request_url+'/login/'
                    base = self.class.http_s_url+'/'+base unless base[0].chr == '/'
                    base += (base.include?("?") ? "&" : "?")
                    get_params = @request.params.map{|k,v| "#{k}=#{v}"}.join('&')+"&" || ""
                    redir_url = base + get_params +'rdr='+URI.escape(@request.path)
                    @request.session.flash[:unauthorized_exception] = {:class => exc.class.name, :message => exc.message}
                end
                #Spider.logger.error "\n\n Sto facendo il REDIRECT GENERALE \n\n"
                redirect(redir_url, Spider::HTTP::TEMPORARY_REDIRECT)
            else
                super
            end
        end
        
        module RequestMethods
            def security
                @security ||= {:users => []}
            end
            def user
                @user
            end
            def user=(val)
                @user = val
            end

            def users
                security[:users]
            end
            
            def auth(user_class)
                return user_class.restore_from_session(self.session)
            end
            
        end

        module ClassMethods

            def require_user(*args)
                klass = args.shift if (args[0] && !args[0].is_a?(Hash))
                params = args[0]
                params ||= {}
                @auth_require_users ||= []
                @auth_require_users << [klass, params]
            end
            
            def auth_require_users
                @auth_require_users || []
            end


        end

    end

end; end
