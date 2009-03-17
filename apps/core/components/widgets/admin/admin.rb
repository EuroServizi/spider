module Spider; module Components
    
    class Admin < Spider::Widget
        tag 'admin'
        
        i_attribute :models, :process => lambda{ |models| models.split(/,\s*/).map{|m| const_get_full(m) } }
        
        def init
            @items = []
        end

        def start
            @models.each do |model|
                crud = Crud.new(@request, @response)
                crud.id = model.name.to_s.gsub('::', '_').downcase
                crud.model = model
                @widgets[:menu].add(model.label_plural, crud)
            end
        end
        
        def execute
            @scene.current = @widgets[:menu].current_label
        end

    end
    
end; end