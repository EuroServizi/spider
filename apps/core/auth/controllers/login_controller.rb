require 'apps/core/auth/lib/login_authenticator'
if Spider.conf.get('auth.enable_auth_hub')
    require 'jwt'
end


module Spider; module Auth
    
    class LoginController < Spider::Controller
        include HTTPMixin
        include Visual

        layout 'login'
        
        def self.default_redirect
            self.http_s_url
        end
        
        def self.logout_redirect
            if Spider.conf.get('auth.enable_auth_hub')
                self.http_s_url('no_login')
            else
                self.http_s_url
            end
        end
        
        def self.users=(val)
            @user_classes = val
        end
        
        def self.users
            @user_classes ||= [Spider::Auth::SuperUser]
        end
        
        def default_redirect
            self.class.default_redirect
        end
                
        __.html
        def index
            #controllo se ho in sessione @request.session[:auth]['username_from_auth_hub'], vuol dire che ho fatto la login
            exception = @request.session.flash[:unauthorized_exception]
            if (@request.params['redirect'])
                @request.params['redirect'].gsub!(Spider::ControllerMixins::HTTPMixin.reverse_proxy_mapping(''),'')
                @scene.redirect = @request.params['redirect']
            end
            if !@request.session[:auth].blank? && !@request.session[:auth]['username_from_auth_hub'].blank?
                redirect @request.params['redirect']
            end
            @scene.unauthorized_msg = exception[:message] if exception && exception[:message] != 'Spider::Auth::Unauthorized'
            @scene.message = @request.session.flash[:login_message] if @request.session.flash[:login_message]
            if Spider.conf.get('auth.enable_auth_hub')
                token_up = get_jwt_token(@request.session.sid, self.class.http_s_url+'/do_login',@request.params['redirect'],'up')
                @scene.login_url_up = Spider.conf.get("auth.redirect_url_auth_hub")+"/sign_in?jwt=#{token_up}"
                token_aad = get_jwt_token(@request.session.sid, self.class.http_s_url+'/do_login',@request.params['redirect'],'aad')
                @scene.login_url_aad = Spider.conf.get("auth.redirect_url_auth_hub")+"/sign_in?jwt=#{token_aad}"
                @scene.login_title = "Autenticazione Necessaria"
                render('no_login')
            else
                render('login') #non mostro questo con auth_hub
            end
        end
        
        def authenticate(params={})
            get_user
        end
        
        def get_user
            self.class.users.each do |user|
                u = user.authenticate(:login, :username => @request.params['login'], :password => @request.params['password'])
                return u if u
            end
            return nil
        end
        
        # Arriva un jwt con questi dati
        # [{"iss"=>"soluzionipa.it",
        #   "auth"=>"up",
        #   "ext_session_id"=>"id_sessione",
        #   "dominio_ente_corrente"=>"http://piovene-new.soluzionipa.it"
        #   "user"=>
        #    {"user_id"=>3,
        #     "name"=>"ciccio",
        #     "first_name"=>"mario",
        #     "last_name"=>"rossis",
        #     "nickname"=>"ciccio",
        #     "email"=>"ciccio@test.it",
        #     "admin"=>true}},
        #  {"typ"=>"JWT", "alg"=>"HS256"}]

        __.html
        def do_login
            #se arriva un parametro jwt controllo i dati, autenticazione da auth_hub
            #metto i dati nel request params
            unless @request.params['jwt'].blank?
                begin
                    hash_jwt = JWT.decode @request.params['jwt'], "6rg1e8r6t1bv8rt1r7y7b86d8fsw8fe6bg1t61v8vsdfs8erer6c18168", 'HS256'
                    #se la sessione non corrisponde non mostro la login. Tolto http o https dall'url
                    if hash_jwt[0]['dominio_ente_corrente'].split("://").last != @request.env['HTTP_HOST']
                        @request.session.flash['unauthorized_msg'] = "Dominio non valido!"
                        redirect self.class.http_s_url('no_login')
                    elsif hash_jwt[0]['dominio_ente_corrente'].blank? && hash_jwt[0]['ext_session_id'] != @request.session.sid
                        @request.session.flash['unauthorized_msg'] = "Sessione non valida!"
                        redirect self.class.http_s_url('no_login')
                    elsif !hash_jwt[0]['user']['admin']
                        @request.session.flash['unauthorized_msg'] = "Utente non amministratore!"
                        redirect self.class.http_s_url('no_login')
                    else
                        #creo uno user per non perdere l'autenticazione, uso un id che non esiste
                        auth_user = hash_jwt[0]['user']
                        @request.session[:auth]= {}
                        if auth_user['admin']
                            user = Spider::Auth::SuperUser.new
                            user.id = 9999999
                            #metto in sessione l'username per ripristinarlo poi
                            @request.session[:auth]['username_from_auth_hub'] = hash_jwt[0]['auth'] == 'aad' || auth_user['nome_cognome'].blank? ? auth_user['email'] : auth_user['nome_cognome']
                        elsif auth_user['admin_servizi']
                            #DEVO CERCARE UN ADMIN SERVIZI SU TABELLE LOCALI..
                            user = Portal::Amministratore.new
                            user.id = 9999999
                            #metto in sessione l'username per ripristinarlo poi
                            @request.session[:auth]['username_from_auth_hub'] = hash_jwt[0]['auth'] == 'aad' || auth_user['nome_cognome'].blank? ? auth_user['email'] : auth_user['nome_cognome']
                        else
                            #utente normale, logout
                        end
                    end
                rescue Exception => exc
                    Spider.logger.error "Errore login: #{exc.message}"
                    @request.session.flash['failed_login'] = true
                    redirect self.class.http_s_url('no_login')
                    done
                end
                
            else
                user = authenticate
            end
            if user
                user.save_to_session(@request.session)
                on_success(user)
                unless success_redirect
                    $out << "Loggato"
                end
            else
                #forzo la cancellazione della sessione per problemi con diversi login 
                # per amministratori servizi
                @request.session[:auth] = nil
                @scene.failed_login = true
                @response.status = 401
                @scene.login = @request.params['login']
                index
            end
        end
        
        __.html :template => 'no_login'
        def no_login 
            @scene.failed_login = @request.session.flash['failed_login']
            @scene.unauthorized_msg = @request.session.flash['unauthorized_msg']
            @scene.did_logout = @request.session.flash['effettuato_logout']
            token_up = get_jwt_token(@request.session.sid, self.class.http_s_url+'/do_login','up')
            @scene.login_url_up = Spider.conf.get("auth.redirect_url_auth_hub")+"/sign_in?jwt=#{token_up}"
            token_aad = get_jwt_token(@request.session.sid, self.class.http_s_url+'/do_login','aad')
            @scene.login_url_aad = Spider.conf.get("auth.redirect_url_auth_hub")+"/sign_in?jwt=#{token_aad}"
            @scene.login_title = "Autenticazione Necessaria"
        end


        def on_success(user)
        end
        
        def success_redirect
            if (@request.params['redirect'] && !@request.params['redirect'].empty?)
                redir_to = ((Spider.site && Spider.site.ssl?) || Spider.conf.get("site.ssl") ? Spider.site.http_s_url : '')+@request.params['redirect']
                redirect(redir_to, Spider::HTTP::SEE_OTHER)
                return true
            elsif(self.default_redirect)
                redirect(self.default_redirect)
                return true
            else
                return false
            end
        end
        
        __.html
        def logout
            @request.session[:auth] = nil
            @scene.did_logout = true
            red = self.class.logout_redirect
            @request.session.flash['effettuato_logout'] = true
            if Spider.conf.get('auth.enable_auth_hub')
                token = get_jwt_token(@request.session.sid,self.class.http_s_url)
                redirect Spider.conf.get("auth.redirect_url_auth_hub")+"/ext_logout?jwt=#{token}"
                done
            end
            if red
                redirect(red)
            else
                redirect('index')
            end
        end
        

        def get_jwt_token(id_sessione,url_back, url_back_redirect=nil,tip_auth=nil)
            payload = {
                        iss: 'soluzionipa.it',
                        auth: tip_auth,
                        ub: url_back,
                        ub_redirect: url_back_redirect,
                        ub_logout: url_back, #questa serve per tornare indietro dopo la logout
                        idc: 'id_di_cosa', #id cliente...
                        ext_session_id: id_sessione
                    }
            token = JWT.encode payload, "6rg1e8r6t1bv8rt1r7y7b86d8fsw8fe6bg1t61v8vsdfs8erer6c18168", 'HS256'

        end



    end
    
    
end; end
