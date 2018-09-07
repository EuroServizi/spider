require 'sass/plugin/configuration'
require 'sass/plugin'

require 'sass'
require 'byebug'
require 'sassc' unless Spider.conf.get('css.sass.use_compass')


module Sass::Plugin::Configuration

  def default_options
    @default_options ||= {
      :css_location       => './public/stylesheets',
      :always_update      => false,
      :always_check       => false,
      :full_exception     => true,
      :cache_location     => File.join(Spider.paths[:tmp], 'sass', '.sass_cache')
      }.freeze
  end
end


# module Sass
#   module Tree

#     class ImportNode < RootNode

#         def initialize(imported_filename)
#           @imported_filename = imported_filename
#           super(nil)
#         end

#     end
#   end
# end


module Spider

    class SassAppImporter < Sass::Importers::Filesystem

        #Modificato per gestire i nomi dei file da importare con il percorso completo come vuole la sassc
        def _find(dir, name, options)
            Spider.apps_by_path.each do |app_name, mod|
                if name.index(app_name) == 0 && File.directory?(File.join(dir, app_name))
                    rel_path = name[app_name.length+1..-1]
                    #patch: con gemma sassc devo mettere anche public nel nome del file di cui fare @import in un scss, con sass no.
                    name = ( name.include?('public') ? name : File.join(app_name, 'public', rel_path) )
                    return super(dir, name, options)
                end
            end
            return super
        end

    end
    
    class SassCompiler

        def self.options
            @options ||= {:load_paths => []}
        end

        def initialize(base_path)
            @base_path = base_path
        end
        
        def compile(src, dest)
            use_compass = false
            if Spider.conf.get('css.sass.use_compass')
                begin
                    require 'compass'
                    #require 'compass/sass_compiler' nuova versione da finire
                    use_compass = true
                rescue LoadError => exc
                    Spider.logger.debug(exc)
                    Spider.logger.debug("Compass not found. Please install 'compass' gem")
                end
            end
            if use_compass
                work_dir = FileUtils.mkdir_p(File.join(Spider.paths[:tmp], 'sass'))
                src_dir = File.dirname(src)
                src_dir = src_dir
                # dest_dir = File.dirname(dest)

                sass_options = Compass.sass_engine_options.merge({
                    :cache_location => File.join(work_dir, '.sass_cache')
                })
                # Spider.apps.each do |name, app|
                #     sass_options[:load_paths] << Sass::Importers::Filesystem.new(app.pub_path)
                # end
                Spider.app_paths.each do |path|
                    sass_options[:load_paths] << SassAppImporter.new(path)
                end

                options = {
                    :project_path => @base_path,
                    :css_dir => 'css', 
                    :sass_dir => 'sass',
                    # :fonts_path => src_dir,
                    # :images_path => src_dir,
                    :fonts_dir => 'fonts',
                    :images_dir => 'img',
                    :javascripts_dir => 'js',
                    :relative_assets => true,
                    :line_comments => Spider.runmode == 'devel' ? true : false,
                    :sass => sass_options,
                    :css_filename => dest
                }
                
                config = Compass::Configuration::Data.new(:spider, options)
                Compass.add_project_configuration(config)
                compiler = Compass::Compiler.new(work_dir, File.dirname(src), File.dirname(dest), options)
                compiler.run
                ##Compass.sass_compiler.compile! nuova versione da finire
            else
                #VECCHIO
                #engine = Sass::Engine.for_file(src, {})
                #output = engine.render
                #NUOVO
                #vedi https://github.com/sass/sassc-ruby/blob/master
                #mettere le options in self.options e passarle al Engine.new
                
                
                work_dir = File.join(Spider.paths[:tmp], 'sass', '.sass_cache')
                FileUtils.mkdir_p(work_dir) unless File.directory?(work_dir)
                
                Spider.app_paths.each do |path|
                    self.class.options[:load_paths] << SassAppImporter.new(path)
                end
                self.class.options[:load_paths] << Spider.paths[:core_apps]
                #TO-DO: ciclare su Spider.apps, se presente 'SPIDER' mettere il load path dell'app in Spider.paths[:core_apps]
                Spider.apps.each_pair{ |chiave_app,app|
                    if chiave_app.include?('Spider')
                        self.class.options[:load_paths] << SassAppImporter.new(Spider.apps[chiave_app].path+"/public/sass") if File.directory?(Spider.apps[chiave_app].path+"/public/sass")
                    else
                        self.class.options[:load_paths] << SassAppImporter.new(Spider.apps[chiave_app].path+"/public/sass") if File.directory?(Spider.apps[chiave_app].path+"/public/sass")
                    end
                }
                #altrimenti usare il path dell'app come portal, moduli ecc
                src_corretto = src.split(".scss")[0]+".scss"        
                #per parametro style vedi esempio https://github.com/sass/sassc-ruby/blob/master/test/output_style_test.rb
                self.class.options['style'] = :sass_style_expanded
                self.class.options['line_comments'] = false
                self.class.options['cache_location'] = work_dir
                #output = SassC::Engine.new(File.read(src_corretto), { style: :sass_style_expanded, line_comments: false, load_paths: load_paths }).render
                output = SassC::Engine.new(File.read(src_corretto), self.class.options).render
                File.open(dest, 'w') do |f|
                    f.write "/* This file is autogenerated; do not edit directly (edit #{src} instead) */\n\n"
                    f.write output
                end
            end
        end
        
    end
    
end