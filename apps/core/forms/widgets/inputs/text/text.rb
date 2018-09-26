module Spider; module Forms
    
    class Text < Input
        tag 'text'
        is_attr_accessor :size, :type => Integer, :default => 25

    end
    
end; end