module Spider

    # The DataType module, if included by a Class, allows to use it as an element type in a Model.
    # The Class must be a subclass of a base type (see Spider::Model.base_types), and allow to be initialized
    # passing the superclass instance as the only parameter; or, it must define maps_to, and override
    # the from_value method.
    #
    # Extends the including class with ClassMethods.
    
    module DataType
        @maps_to = nil
        
        def self.included(klass)
            klass.extend(ClassMethods)
        end
        
        module ClassMethods
            
            # This method will be called when instantiating the DataType from a base type.
            # The default implementation calls the DataType constructor passing it the value.
            def from_value(value)
                return nil if value.nil?
                return self.new(value)
            end
            
            # Sets and/or returns the base type the DataType is converted to by the Mapper when storing.
            def maps_to(val=nil)
                @maps_to = val if val
                @maps_to
            end
            
            # Sets and/or returns a base type the DataType will be converted to when loaded by the Mapper.
            def maps_back_to(val=nil)
                @maps_back_to = val if val
                @maps_back_to
            end
            
            # Defines a list of Element attributes the DataType will use. They will be available in the @attributes
            # instance variable.
            def take_attributes(*list)
                if (list)
                    @take_attributes = list
                else
                    @take_attributes || []
                end
            end
            
        end
        
        # Returns the DataType attributes, as set in the Model Element.
        # (See ClassMethods.take_attributes).
        def attributes
            @attributes ||= {}
        end
        
        # Returns a representation of the DataType for storing.
        def map(mapper_type)
            self
        end
        
        # FIXME: why does this take a val? Is it used?
        def map_back(mapper_type, val) # :nodoc:
            val.is_a?(self.class) ? val : self.class.new(val)
        end
        
        # This method may be overridden by subclasses and provide different textual representation for named formats.
        # Possible formats are :normal, :short, :medium, :long, :full.
        # The default implementation ignores the format and just calls to_s.
        def format(format)
            self.to_s
        end
        
    end
    
end