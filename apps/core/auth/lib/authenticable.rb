module Spider; module Auth
    
    module Authenticable
        
        def self.included(klass)
            klass.extend(ClassMethods)
        end
        
        def authenticated(method)
            @authentications ||= {}
            @authentications[method] = true
        end
        
        def authenticated?(method=nil)
            return false unless @authentications
            if (method)
                @authentications[method]
            else
                return @authentications
            end
        end
        
        def save_to_session(session)
            session[:auth] ||= {}
            h = self.to_session_hash
            h[:authentications] = @authentications
            session[:auth][self.class.name] = h
        end
        
        def to_session_hash
            if (self.is_a?(Spider::Model::BaseModel))
                h = {}
                self.class.primary_keys.each{ |k| h[k.name] = self.get(k) }
                return h
            else
                raise "Authenticable classes must implement to_session_hash and self.restore_session_hash"
            end
        end
        
        module ClassMethods
        
            def register_authentication(method)
                @auth_methods ||= []
                @auth_methods << method
            end
        
            def authenticate(method, params)
                methods = method ? method : @auth_methods
                methods = method.is_a?(Array) ? method : [method]
                res = nil
                if (methods)
                    methods.each do |method|
                        res = self.send("authenticate_"+method.to_s, params)
                        break if res
                    end
                end
                res.authenticated(method) if res
                return res
            end
        
            def restore_from_session(session)
                auth_name = self.name.to_s
                return nil unless session[:auth] && session[:auth][auth_name]
                h = session[:auth][auth_name]
                authentications = h.delete(:authentications) || []
                obj = restore_session_hash(session[:auth][auth_name],session[:auth])
                authentications.each do |method|
                    obj.authenticated(method)
                end
                return obj
            end
            
            def restore(request)
                restore_from_session(request.session)
            end
        
            def restore_session_hash(saved, auth_params_auth_hub=nil)
                if (self.subclass_of?(Spider::Model::BaseModel))
                    user_restored = self.new(saved)
                    #se passo come id 9999999 sto usando uno user da auth_hub fittizio, carico username da sessione
                    if user_restored.id == 9999999 && !auth_params_auth_hub.blank? && !auth_params_auth_hub['username_from_auth_hub'].blank?
                        user_restored.username = auth_params_auth_hub['username_from_auth_hub']
                        #metto nel 
                        user_restored.global_admin = true if user_restored.class.to_s == "Spider::Auth::SuperUser"
                    end
                    return user_restored
                else
                    raise "Authenticable classes must implement to_session_hash and self.restore_session_hash"
                end
            end
            
        end
        
    end
    
    
end; end