require 'spiderfw/create'

class InitCommand < CmdParse::Command


    def initialize
        super( 'init', true, true )
        @short_desc = _("Create a working dir for development or installation")
#        @description = _("")

        app = CmdParse::Command.new( 'app', false )
        app.short_desc = _("Create a new application")
        app.options = CmdParse::OptionParserWrapper.new do |opt|
            opt.on("--path", 
                   _("The path where to create the app (defaults to the app folder under the current path)"),
                   "-p"){ |path|
                @path = path
            }
            opt.on("--module", _("The module name; by default, the app name will be camelized"), "-m"){ |module_name|
                @module_name = module_name
            }
        end
        app.set_execution_block do |names|
            @path ||= Dir.pwd+'/apps'
            names.each do |name|
                Spider::Create.app(name, @path, @module_name)
                puts "Created app #{name} at #{@path}/#{name}" if ($verbose)
            end
        end
        self.add_command(app, false)
        
        install = CmdParse::Command.new('install', false)
        install.short_desc = _("Create an installation")
        install.options = CmdParse::OptionParserWrapper.new do |opt|
            opt.on("--path", 
                   _("The path where to create the installation (defaults to the path)"),
                   "-p"){ |path|
                @path = path
            }
        end
        install.set_execution_block do |installs|
            @path ||= Dir.pwd
            installs.each do |inst|
                Spider::Create.install(inst, @path)
            end
        end
        self.add_command(install, false)


    end

end