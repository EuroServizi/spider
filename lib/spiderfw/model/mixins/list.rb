module Spider; module Model
    
    module List
        
        def self.included(model)
            model.extend(ClassMethods)
            model.mapper_include(MapperMethods)
        end
        
        def list_mixin_modified_elements
            @list_mixin_modified_elements ||= {}
        end
        
        module MapperMethods
            
            def before_save(obj, mode)
                if (obj.list_mixin_modified_elements)
                    obj.list_mixin_modified_elements.each do |name, old|
                        new_val = nil
                        obj.save_mode do
                            new_val = obj.get(name)
                        end
                        if (new_val < old)
                            move_up_list(name, new_val, old-1)
                        else
                            move_down_list(name, old+1, new_val)
                        end
                    end
                end
                super(obj, mode)
            end
            
            def before_delete(objects)
                @model.lists.each do |list_el|
                    objects.each do |obj|
                        val = obj.get(list_el)
                        move_down_list(list_el.name, val) if val
                    end
                end
                super(objects)
            end
            
            def move_up_list(element_name, from, to=nil)
                expr = ":#{element_name} + 1"
                cond = Condition.and
                cond.set(element_name, '>=', from)
                cond.set(element_name, '<=', to) if to
                bulk_update({element_name => Spider::QueryFuncs::Expression.new(expr)}, cond)
            end
            
            def move_down_list(element_name, from, to=nil)
                expr = ":#{element_name} - 1"
                cond = Condition.and
                cond.set(element_name, '>=', from)
                cond.set(element_name, '<=', to) if to
                bulk_update({element_name => Spider::QueryFuncs::Expression.new(expr)}, cond)
            end
            
        end
        
        
        module ClassMethods
            
            def lists
                elements_array.select{ |el| el.attributes[:list] }
            end
            
            def list(name, attributes={})
                attributes[:list] = true
                element(name, Fixnum, attributes)
                observe_element(name) do |obj, el, old_val|
                    obj.save_mode do
                        obj.list_mixin_modified_elements[name] = obj.get(el)
                    end
                end
                
                (class << self; self; end).instance_eval do
                    
                    define_method("#{name}_last") do
                        qs = self.all.order_by(name).limit(1)
                        return qs[0]
                    end
                    
                end
                
                define_method("insert_last_#{name}") do
                    # FIXME: locking!
                    last = self.class.send("#{name}_last")
                    max = last ? last.get(name) : 0
                    set(name, max + 1)
                end
            end
            
            

            
        end
        
    end
    
end; end