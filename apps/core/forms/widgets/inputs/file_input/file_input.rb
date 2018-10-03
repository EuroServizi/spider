begin
    require 'ftools'
rescue LoadError
end

module Spider; module Forms
    
    class FileInput < Input
        tag 'file'
        is_attr_accessor :save_path, :type => String, :default => Proc.new{ Spider.paths[:var]+'/data/uploaded_files' }
        
        def needs_multipart?
            true
        end
        
        def prepare
            raise "No save path defined" unless @save_path
            raise "Save path #{@save_path} is not a directory" unless File.directory?(File.dirname(@save_path))
            FileUtils.mkdir_p(@save_path) unless File.directory?(@save_path)

            super
        end
        
        def file_vuoto?
            @value && @value == 'file_caricato_vuoto'
        end

        def has_value?
            @value && (!@value.is_a?(String) || !@value.empty?)
        end

        #quando si carica il file
        #(byebug) val
        #{"clear"=>"on", "file_name"=>"/home/fabiano/soluzionipa/www/siti/openweb2/data/uploaded_files/moduli/6491ac275dc78b76a089/filezerok.txt", "file"=>#<Spider::UploadedFile:/home/fabiano/soluzionipa/www/siti/nuova_grafica/tmp/uploaded20181001-14896-19u0cun>}
        #quando un file e' gia stato caricato
        #(byebug) val
        #{"file_name"=>"/home/fabiano/soluzionipa/www/siti/openweb2/data/uploaded_files/moduli/6491ac275dc78b76a089/filezerok.txt", "file"=>""}

        def prepare_value(val)
            return nil if !val || val.empty?
            
            #ho un file da caricare
            if val['file'] && !val['file'].is_a?(String)
                #se il file non vuoto
                if val['file'].lstat.size > 0
                    dest_path = @save_path+'/'+val['file'].filename
                    FileUtils.copy(val['file'].path, dest_path)
                else #file vuoto
                    self.value = nil
                    return 'file_caricato_vuoto' if val['clear'].blank?
                end
            elsif !val['file_name'].blank? && val['file'].blank?
                #file precedentemente caricato, controllo se esiste il file nel filesystem
                return 'file_caricato_vuoto' if !val['file_name'].blank? && !File.exists?(val['file_name']) && val['clear'].blank?
            else
                #niente
            end
            #se clicco su pulisci cancello il file
            if val['clear'] == 'on'
                FileUtils.rm_f(val['file_name']) if File.exist?(val['file_name'])
                self.value = nil
                return 'cancellato' if val['file'].blank?
            end
            return (dest_path.blank? ? self.value : dest_path)
        end

        __.action
        def view_file
            raise NotFound.new(@value.to_s) unless @value && @value.file?
            @response.headers['Content-Description'] = 'File Transfer'
            @response.headers['Content-Disposition'] = "attachment; filename=\"#{@value.basename}\""
            output_static(@value.to_s)
        end
        
    end
    
end; end