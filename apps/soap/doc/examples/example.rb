require 'apps/soap/_init.rb'

module SoapTest
    
    class SoapTestController < Spider::SoapController
        SumResponse = SoapStruct(:a => Finxum, :b => Integer, :res => Integer)
        FloatArray = SoapArray(Float)
        
        soap :sum, :in => [[:a, Integer], [:b, Integer]], :return => SumResponse
        soap :random, :return => FloatArray
        
        def sum(a, b)
            return {:a => a, :b => b, :res => a+b}
        end
        
        
        def random
            res = []
            0.upto(9) do
                res << rand
            end
            return res
        end
        
    end
    
    
end