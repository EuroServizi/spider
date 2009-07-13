module Spider; module Model
    
    module Storage
        
        
        def self.get_storage(type, url)
            case type
            when 'db'
                adapter = url.match(/^(.+?):\/\//)[1]
                case adapter
                when 'sqlite'
                    storage = Db::SQLite.new(url)
                when 'oci8'
                    storage = Db::OCI8.new(url)
                when 'mysql'
                    storage = Db::Mysql.new(url)
                end
            end
        end
        
        module StorageResult
            attr_accessor :total_rows
            
        end
        
        class StorageException < RuntimeError
        end
        
        ###############################
        #   Autoload                  #
        ###############################
        
        Storage.autoload(:Db, 'spiderfw/model/storage/db/db')
                
    end
    
end; end