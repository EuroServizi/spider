begin
    require 'ftools'
rescue LoadError
end

module Spider; module Forms
    
    class FileInput < Input
        tag 'file'
        is_attr_accessor :save_path, :type => String, :default => lambda{ Spider.paths[:var]+'/data/uploaded_files' }
        
        def needs_multipart?
            true
        end
        
        def prepare
            raise "No save path defined" unless @save_path
            raise "Save path #{@save_path} is not a directory" unless File.directory?(File.dirname(@save_path))
            FileUtils.mkdir_p(@save_path) unless File.directory?(@save_path)

            super
        end
        
        
        def prepare_value(val)
            return nil if !val || val.empty?
            if val['file'] && !val['file'].is_a?(String)
                dest_path = @save_path+'/'+val['file'].filename
                FileUtils.copy(val['file'].path, dest_path)
                return dest_path
            elsif val['clear']
                self.value = nil
                return
            end
            return @value
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