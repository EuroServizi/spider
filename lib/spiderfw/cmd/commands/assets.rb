module Spider::CommandLine

    class AssetsCommand < CmdParse::Command


        def initialize
            super('assets', true, true )
            @short_desc = "Gestisci assets"
        end
    end

end