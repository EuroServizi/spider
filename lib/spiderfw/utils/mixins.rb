class String
    def to_bool
		return true if self == true || self =~ (/(true|Vero|t|yes|si|y|1)$/i)
		return false if self == false || self.blank? || self =~ (/(false|Falso|f|no|n|0)$/i)
		raise ArgumentError.new("invalid value for Boolean: \"#{self}\"")
    end
end