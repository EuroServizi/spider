module Spider; module Messenger

    class AdminController < Spider::Admin::AppAdminController
        layout ['/core/admin/admin', 'admin/_admin'], :assets => 'messenger'

        include MessengerHelper rescue NameError

        Messenger.queues.keys.each do |queue|
            route queue.to_s, :queue, :do => Proc.new{ |action| @queue = action.to_sym }
        end

        route /\/invio_sms/, :invio_sms
        route /\/esito_invio_sms/, :esito_invio_sms


        def before(action='', *params)
            super
            @scene.queues = []
            @scene.queue_info = {}
            Messenger.queues.each do |name, details|
                next if  Spider.conf.get("messenger.#{name}.backends").empty?
                @scene.queues << name
                model = Spider::Messenger.const_get(details[:model])
                @scene.queue_info[name] = {
                    :label => details[:label]
                }
            end
        end

        __.html :template => 'admin/index'
        def index
            @scene.queues.each do |name|
                details = Spider::Messenger.queues[name]
                model = Spider::Messenger.const_get(details[:model])
                @scene.queue_info[name].merge!({
                    :sent => model.sent_messages.total_rows,
                    :queued => model.queued_messages.total_rows,
                    :failed => model.failed_messages.total_rows
                })
            end

        end

        __.html :template => 'admin/queue'
        def queue(id=nil)
            q = Messenger.queues[@queue]
            model = Spider::Messenger.const_get(q[:model])
            @scene.queue = @queue
            @scene.title = q[:label]
            @scene.admin_breadcrumb << {:label => @scene.title, :url => self.class.http_s_url(@queue)}

            if id
                return view_message(@queue, id)
            end
            @scene.msg_view_url = self.class.http_s_url(@queue)+'/'
            @scene.queued = model.queued_messages
            @scene.sent = model.sent_messages
            @scene.failed = model.failed_messages
                      
        end

        def view_message(queue, id)
            details = Spider::Messenger.queues[queue]
            model = Spider::Messenger.const_get(details[:model])
            @scene.message = model.load(:id => id)
            raise NotFound.new("Message #{queue} #{id}") unless @scene.message
            @scene.admin_breadcrumb << {:label => id, :url => self.class.http_s_url("#{queue}/#{id}")}
            render("admin/view_#{queue}")
        end

        __.html :template => 'admin/invio_sms'
        def invio_sms
            @scene.title = 'Invia sms'
            @scene.admin_breadcrumb << {:label => @scene.title, :url => self.class.http_s_url('invio_sms')}
            dati = {
                'testo_sms' => '',
                'numero' => '',
                'file_destinatari' => ''
            }

            if @request.post?
                sms = nil
                dati = @request.params['dati']
                errori = []

                if dati['testo_sms'].blank?
                    @scene.error_testo_sms = 'error'
                    errori << "Deve essere inserito il testo dell'sms da inviare."
                end
                if dati['numero'].blank? && dati['file_destinatari'].blank?
                    @scene.error_numero = 'error' if dati['numero'].blank?
                    @scene.error_file_destinatari = 'error' if dati['file_destinatari'].blank?
                    errori << 'Deve essere inserito il numero del destinatario o caricato il file con i vari destinatari.' 
                end
                if !dati['numero'].blank? && (dati['numero'] =~ /^[0-9]+$/).nil?
                    @scene.error_numero = 'error'
                    errori << 'Il numero di telefono deve essere composto esclusivamente da caratteri numerici.'
                end
                
                if errori.blank?
                    #invio sms
                    unless dati['numero'].blank?
                        #se ci sono # li tolgo per mandare il messaggio al numero inserito
                        testo_pulito = dati['testo_sms'].gsub(/#[0-9]/, '')
                        cellulare = dati['numero']
                        sms = MessengerHelper.send_sms(cellulare, testo_pulito)
                        if sms.blank?
                            Spider.logger.error "Numero #{cellulare} non valido"
                        end
                    end
                    unless dati['file_destinatari'].blank?
                        begin
                            #parserizzo il file csv uploadato e mando gli sms
                            if RUBY_VERSION =~ /1.8/
                                CSV.parse(dati['file_destinatari'].read,fs = ';').each do |row|
                                    next if (row[0] =~ /[0-9]+$/).nil?
                                    sms = invio_sms_da_riga_csv(row, dati)  
                                end
                                dati['file_destinatari'].rewind
                                if sms.blank?
                                    CSV.parse(dati['file_destinatari'].read,fs=",").each do |row|
                                        next if (row[0] =~ /[0-9]+$/).nil?
                                        sms = invio_sms_da_riga_csv(row, dati)  
                                    end
                                end
                            else #RUBY_VERSION =~ /1.9.3/ 
                                CSV.parse(dati['file_destinatari'].read,{:col_sep => ';'}).each do |row|
                                    next if (row[0] =~ /[0-9]+$/).nil?
                                    sms = invio_sms_da_riga_csv(row, dati)  
                                end
                                dati['file_destinatari'].rewind
                                if sms.blank?
                                    CSV.parse(dati['file_destinatari'].read,{:col_sep => ','}).each do |row|
                                        next if (row[0] =~ /[0-9]+$/).nil?
                                        sms = invio_sms_da_riga_csv(row, dati)  
                                    end
                                end

                            end
                        rescue Exception => exc
                            Spider.logger.debug "Uso il separatore , per i valori del csv"
                            dati['file_destinatari'].rewind
                            if RUBY_VERSION =~ /1.8/
                                CSV.parse(dati['file_destinatari'].read,fs=",").each do |row|
                                    next if (row[0] =~ /[0-9]+$/).nil?
                                    sms = invio_sms_da_riga_csv(row, dati)  
                                end
                            else #RUBY_VERSION =~ /1.9.3/
                                CSV.parse(dati['file_destinatari'].read,{:col_sep => ','}).each do |row|
                                    next if (row[0] =~ /[0-9]+$/).nil?
                                    sms = invio_sms_da_riga_csv(row, dati)  
                                end
                            end
                        end    
                    end
                    if !sms.blank?
                        @request.session.flash['esito_azione'] = "Sms inviato correttamente."
                        redirect self.class.http_s_url('esito_invio_sms')
                    else
                        #visualizzo negli errori se il numero di cellulare non e corretto
                        errori << "Numero di cellulare non corretto."
                        @scene.errori = errori
                        
                    end

                else
                @scene.errori = errori
                   
                end
            end
            @scene.dati = dati 

        end

        def invio_sms_da_riga_csv(row, dati)
            testo_sms = dati['testo_sms']
            #sostituisco i segnaposto
            if testo_sms.include?('#')
                row.each_index{ |index|
                    testo_sms = testo_sms.gsub('#'+index.to_s, row[index])
                }
                #pulisco il testo dai segnaposto rimanenti
                testo_sms = testo_sms.gsub(/#[0-9]/, '')
            end
            
            cellulare = row[0]
            unless cellulare.blank?
                sms = MessengerHelper.send_sms(cellulare, testo_sms)
                if sms.blank?
                    Spider.logger.error "Numero #{cellulare} non valido"
                end
            end
            sms
        end

        __.html :template => 'admin/esito_invio_sms'
        def esito_invio_sms
            @scene.title = 'Esito invio sms'
            @scene.admin_breadcrumb << {:label => @scene.title, :url => self.class.http_s_url('esito_invio_sms')}
            esito = @request.session.flash['esito_azione']
            @scene.esito_azione = esito unless esito.nil?
        end


    end

end; end