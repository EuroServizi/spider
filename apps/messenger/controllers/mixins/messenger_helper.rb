require 'erb'
require 'mail'

Spider.register_resource_type(:email, :extensions => ['erb'], :path => 'templates/email')

module Spider; module Messenger
    
    module MessengerHelper
        
        # Compiles an e-mail from given template and scene, and sends it using
        # #Messenger::email
        # template is the template name (found in templates/email), without the extension
        # will use template.html.erb and template.txt.erb if they exist, template.erb otherwise.
        # attachments must be an array, which items can be strings (the path to the file)
        # or Hashes:
        # {:filename => 'filename.png', :content => File.read('/path/to/file.jpg'),
        #   :mime_type => 'mime/type'}
        # Attachments will be passed to the Mail gem (https://github.com/mikel/mail), so any syntax allowed by Mail
        # can be used
        def send_email(template, scene, from, to, headers={}, attachments=[], params={})
            klass = self.class if self.class.respond_to?(:find_resouce_path)
            klass ||= self.class.app if self.class.respond_to?(:app)
            klass ||= Spider.home
            msg = Spider::Messenger::MessengerHelper.send_email(klass, template, scene, from, to, headers, attachments, params)
            sent_email(msg.ticket)
            msg
        end

        def send_sms(to, text, params={})
            to = "+39"+to if !to.include?("+")
            msg = Spider::Messenger.sms(to, text, params)
            sent_sms(msg.ticket)
            msg
        end
        
        def self.send_email(klass, template, scene, from, to, headers={}, attachments=[], params={})
            path_txt = klass.find_resource_path(:email, template+'.txt')
            path_txt = nil unless path_txt && File.exist?(path_txt)
            path_html = klass.find_resource_path(:email, template+'.html')
            path_html = nil unless path_html && File.exist?(path_html)

            #conversione dei valori all'interno della scene
            if RUBY_VERSION =~ /1.8/
                scene.each_pair{ |key,val| val = iconv.iconv(val) }
            elsif RUBY_VERSION =~ /1.9/
                #scene.each_pair{ |key,val| val = val.encode('cp1252','utf-8').force_encoding('utf-8') if val.is_a?(String) }
                scene.each_pair{ |key,val| val.respond_to?(:force_encoding) ? val.force_encoding('UTF-8') : val  }
            end
            scene_binding = scene.instance_eval{ binding }
            if (path_txt || path_html)
                text = ERB.new( IO.read(path_txt) ).result(scene_binding) if path_txt
                html = ERB.new( IO.read(path_html) ).result(scene_binding) if path_html
            else
                path = klass.find_resource_path(:email, template)
                text = ERB.new( IO.read(path) ).result(scene_binding)
            end

            mail = Mail.new
            mail[:to] = (to.respond_to?(:force_encoding) ? to.force_encoding('UTF-8') : to)
            mail[:from] = (from.respond_to?(:force_encoding) ? from.force_encoding('UTF-8') : from)
            mail.charset = "UTF-8"
            headers.each do |key, value|
                mail[key] = (value.respond_to?(:force_encoding) ? value.force_encoding('UTF-8') : value)
            end

            if html
                mail.html_part do
                    content_type 'text/html; charset=UTF-8'
                    body html
                end 
            end  
            if attachments && !attachments.empty?
                mail.text_part do
                    body text
                end       
            else
                mail.body = text
            end

            if attachments && !attachments.empty?
                attachments.each do |att|
                    if att.is_a?(Hash)
                        filename = att.delete(:filename)
                        mail.attachments[filename] = att
                    else
                        mail.add_file(att)
                    end
                end
            end
            mail_headers, mail_body = mail.to_s.split("\r\n\r\n", 2)
            mail_headers += "\r\n"
            Messenger.email(from, to, mail_headers, mail_body, params)
        end
        
        def sent_email(ticket)
            sent_message(ticket, :email)
        end

        def sent_sms(ticket)
            sent_message(ticket, :sms)
        end

        def sent_message(ticket, type)
            return unless ticket
            type = type.to_sym
            @messenger_sent = Spider::Request.current[:messenger_sent]
            @messenger_sent ||= {}
            @messenger_sent[type] ||= []
            @messenger_sent[type] << ticket
            Spider::Request.current[:messenger_sent] = @messenger_sent
        end
        
        def after(action='', *params)
            @messenger_sent = Spider::Request.current[:messenger_sent]
            return super unless Spider.conf.get('messenger.send_immediate') && @messenger_sent
            @messenger_sent.each do |type, msgs|
                Spider::Messenger.process_queue(type, msgs)
            end
        end
        
    end
    
end; end
