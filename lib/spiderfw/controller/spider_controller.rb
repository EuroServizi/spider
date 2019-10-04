require 'spiderfw/controller/mixins/http_mixin'
module Spider
    
    class SpiderController < Controller
        include ::Spider::ControllerMixins::HTTPMixin
        include StaticContent
        
        
        def self.pub_path
            File.join($SPIDER_PATH, 'public')
        end
        
        def self.pub_url
            HTTPMixin.reverse_proxy_mapping('/spider/public')
        end
        
                
    end
    
    
end