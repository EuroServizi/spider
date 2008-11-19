module Spider
    
    module App
        
        def self.included(mod)
            mod.module_eval do
                @controller_class ||= :MainController
                class << self
                    attr_reader :path, :pub_path, :test_path, :setup_path
                    
                    def init
                        @pub_path ||= @path+'/public'
                        @test_path ||= @path+'/test'
                        @setup_path ||= @path+'/setup'
                    end
                    
                    def controller_class
                        #controllers = self.const_get(:Controllers)
                        const_defined?(@controller_class) ? const_get(@controller_class) : Spider::Controller
                    end
                    
                    def models
                        self.constants.map{ |m| const_get(m) }.select{ |m| m.subclass_of? Spider::Model::BaseModel }
                    end
                    
                    def controllers
                        self.constants.map{ |m| const_get(m) }.select{ |m| m.subclass_of? Spider::Controller }
                    end
                    
                end
                
                # controllers = Spider::App::Controllers.clone
                # controllers.app = mod
                # Spider.logger.debug("Controllers.app")
                # Spider.logger.debug(controllers.to_s)
                # Spider.logger.debug(controllers.app)
                #     
                # mod.const_set(:Controllers, controllers) unless mod.const_defined?(:Controllers)
                # Spider.logger.debug(Controllers)
            end
            mod.init()
            # routes_file = "#{mod.path}/routes.rb"
            # if (File.exist?(routes_file))
            #     load(routes_file)
            # else
            #     mod.controller_class.route('/', mod.name+'::MainController')
            # end
            Spider::add_app(mod)
        end
        
        # module Controllers
        #     def self.app=(app)
        #         @app = app
        #     end
        #     def self.app
        #         @app
        #     end
        # 
        # end
        
    end
    
end