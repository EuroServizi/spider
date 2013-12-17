require 'digest/md5'
require 'net/http'
require 'iconv'

module Spider::Messenger

    module Skebby

        def self.parametri(username,password,to,from,testo,operation="TEXT",udh="")
              
        end

        def self.do_post_request(uri,data)
              response = Net::HTTP.post_form(uri,data) 
        end


        def self.check_response_http(response)
              case response
              when Net::HTTPSuccess
                  if response.body !~ /^OK/
                      raise response.body.to_s
                  else
                      return true 
                  end
              else
                  #solleva un eccezione
                  raise response.class.to_s
              end         
        end

    end      

end