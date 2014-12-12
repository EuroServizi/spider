major, minor, patch = RUBY_VERSION.split('.').map{ |v| v.to_i }
if major <= 1 && minor <= 8

    class Object
        module InstanceExecHelper; end
        include InstanceExecHelper
        def instance_exec(*args, &block)
            begin
                old_critical, Thread.critical = Thread.critical, true
                n = 0
                n += 1 while respond_to?(mname="__instance_exec#{n}")
                InstanceExecHelper.module_eval{ define_method(mname, &block) }
            ensure
                Thread.critical = old_critical
            end
            begin
                ret = send(mname, *args)
            ensure
                InstanceExecHelper.module_eval{ remove_method(mname) } rescue nil
            end
            ret
        end
    end
    
end

class Object
    
    def blank?
        respond_to?(:empty?) ? empty? : !self
    end

    #metodo ricorsivo per convertire in utf-8 tutto un oggetto con array o hash all'interno
    def convert_object(encoding='UTF-8')
        if self.respond_to?(:each_pair)
            self.each_pair{ |chiave, valore|
                valore.convert_object
            }
        elsif self.respond_to?(:each) && !self.is_a?(String)
            #controllo se sto ciclando su un modello
            if self.class < Spider::Model::BaseModel
                #ritorna le chiavi degli elementi
                
                self.class.elements.each_pair{ |chiave_hash_modello, valore_hash_modello|
                    self[chiave_hash_modello].convert_object unless self[chiave_hash_modello].respond_to?(:model)
                }
            else
                #converto i singoli valori
                self.each{ |valore_array|
                    valore_array.convert_object
                }
            end
        elsif self.is_a?(String)
            if RUBY_VERSION =~ /1.8/
                require 'iconv'
                self.replace(Iconv.iconv(encoding, encoding, self).first)
            elsif RUBY_VERSION =~ /1.9/
                self_dup = self.dup
                self.replace(self_dup.force_encoding(encoding)) unless self.frozen?
            end
        end
    end


    
end