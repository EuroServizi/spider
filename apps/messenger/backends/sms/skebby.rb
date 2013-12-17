require 'apps/messenger/lib/sms_backend'
require 'apps/messenger/lib/backends/skebby'
require 'net/http'
require 'uri'
require 'cgi'



module Spider; module Messenger; module Backends; module SMS

    module Skebby
        include Messenger::SMSBackend

        class SkebbyGatewaySendSMS
   
            def initialize(username = '', password = '')
                @url = 'http://gateway.skebby.it/api/send/smseasy/advanced/http.php'
         
                @parameters = {
                    'username'      => username,
                    'password'      => password,
                }
            end
         
            def sendSMS(method, text, recipients, options = {})
              unless recipients.kind_of?(Array)
                raise("recipients must be an array")
              end
             
              @parameters['method'] = method
              @parameters['text'] = text
               
              @parameters["recipients[]"] = recipients
           
            unless options[:senderNumber].nil?
             @parameters['sender_number'] = options[:senderNumber]
            end
         
            unless options[:senderString].nil?
             @parameters['sender_string'] = options[:senderString]
            end
         
            unless options[:charset].nil?
             @parameters['charset'] = options[:charset]
            end
                 
            @parameters.each {|key, value| puts "#{key} is #{value}" }    
                 
                @response = Net::HTTP.post_form(URI(@url), @parameters)
                if @response.message == "OK"
                    true
                else
                    false
                end
                 
            end
             
            def getCredit()
               
            @parameters['method']   = 'get_credit'
             
                @response = Net::HTTP.post_form(URI(@url), @parameters)
                if @response.message == "OK"
                    true
                else
                    false
                end
            end
             
            def getResponse
                result = {}
                @response.body.split('&').each do |res|
                    if res != ''
                        temp = res.split('=')
                        if temp.size > 1
                            result[temp[0]] = temp[1]
                        end
                    end
                end
                return result
            end
         
            def printResponse
                result = self.getResponse
                if result.has_key?('status') and result['status'] == 'success'
                    puts "Success, response contains:"
                    result.each do |key,value|
                        puts "\t#{key} => #{CGI::unescape(value)}"
                    end
                    true
                else
                    # ------------------------------------------------------------------
                    # Controlla la documentazione completa all'indirizzo http:#www.skebby.it/business/index/send-docs/ 
                    # ------------------------------------------------------------------
                    # Per i possibili errori si veda http:#www.skebby.it/business/index/send-docs/#errorCodesSection
                    # ATTENZIONE: in caso di errore Non si deve riprovare l'invio, trattandosi di errori bloccanti
                    # ------------------------------------------------------------------        
                    puts "Error, trace is:"
                    result.each do |key,value|
                        puts "\t#{key} => #{CGI::unescape(value)}"
                    end
                    false
                end
            end
         
        end


        def self.send_message(msg)
            Spider.logger.debug("**Sending SMS with skebby**")
            username = Spider.conf.get('messenger.skebby.username')
            password = Spider.conf.get('messenger.skebby.password')
            from = Spider.conf.get('messenger.skebby.from')    
            to = msg.to
            text = msg.text

            gw = SkebbyGatewaySendSMS.new(username, password)
 
                         
            #Invio SMS Classic con mittente personalizzato di tipo alfanumerico
            result = gw.sendSMS('send_sms_classic', text, to, from )
             
            #Invio SMS Basic
            #result = gw.sendSMS('send_sms_basic', 'Hi Mike, how are you? By John', recipients )
             
            #Invio SMS Classic con mittente personalizzato di tipo numerico
            #result = gw.sendSMS('send_sms_classic', 'Hi Mike, how are you', recipients, { :senderNumber => '393471234567' } )
             
            #Invio SMS Classic con notifica(report) con mittente personalizzato di tipo alfanumerico - Invio SMS Classic Plus
            #result = gw.sendSMS('send_sms_classic_report', 'Hi Mike, how are you', recipients, { :senderString => 'Jhon' } )
             
            #Invio SMS Classic con notifica(report) con mittente personalizzato di tipo numerico - Invio SMS Classic Plus
            #result = gw.sendSMS('send_sms_classic_report', 'Hi Mike, how are you', recipients, { :senderNumber => '393471234567' } )
             
            #Richiesta credito
            #result = gw.getCredit()
             
            if result
                gw.printResponse
            else
                puts "Error in the HTTP request"
            end  
                
        end






    end



end; end; end; end    