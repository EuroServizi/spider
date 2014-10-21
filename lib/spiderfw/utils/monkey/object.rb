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

    #converte il valore stesso in utf-8 
    def convert_value(encoding='UTF-8')
        if self.is_a?(String)
            if RUBY_VERSION =~ /1.8/
                require 'iconv'
                return Iconv.iconv("#{encoding}//IGNORE", encoding, self)
            elsif RUBY_VERSION =~ /1.9/
                return self.respond_to?(:force_encoding) ? self.force_encoding(encoding) : self     
            else
                return self
            end
        end
        self
    end

    #metodo ricorsivo per convertire in utf-8 tutto un oggetto con array o hash all'interno
    def convert_object(encoding='UTF-8')
        if self.respond_to?(:each_pair)
            self.each_pair{ |chiave, valore|
                valore.convert_object
            }
        elsif self.respond_to?(:each) && !self.is_a?(String)
            self.each{ |valore_array|
                valore_array.convert_object
            }
        else
            #caso base in cui chiamo il convert_value
            return self.convert_value
        end
    end


    
end