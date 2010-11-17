require 'apps/messenger/lib/sms_backend'

module Spider; module Messenger; module Backends; module SMS
    
    module SmsTools
        include Messenger::SMSBackend
        
        def self.send(msg)
            Spider.logger.debug("Sending SMS #{msg.ticket}")
            File.new(File.join(Spider.conf.get('messenger.smstools.path_outgoing'), msg.ticket), 'w') do |f|
                f << "To: #{msg.to}\n\n"
                f << msg.text
            end
            return true
        end
        
        
        def self.update_statuses
            Messenger::SMS.where{ |sms| sms.status == :backend }.each do |msg|
                path_sent = nil
                path_failed = nil
                if p_sent = Spider.conf.get('messenger.smstools.path_sent')
                    path_sent = File.join(p_sent, msg.ticket)
                end
                if p_failed = Spider.conf.get('messenger.smstools.path_failed')
                    path_failed = File.join(p_failed, msg.ticket)
                end
                if path_sent && File.exist?(path_sent)
                    msg.status = :sent
                    msg.save
                    File.rm(path_failed) if Spider.conf.get('messenger.smstools.remove_sent')
                elsif path_failed && File.exist?(path_failed)
                    msg.add_failure
                    msg.save
                    File.rm(path_failed) if Spider.conf.get('messenger.smstools.remove_failed')
                end
            end
        end
        
        
        
    end
    
end; end; end; end