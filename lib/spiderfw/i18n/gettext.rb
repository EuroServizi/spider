require 'fast_gettext'
require 'locale'
include FastGettext::Translation
FastGettext.add_text_domain('spider', :path => File.join($SPIDER_PATH, 'data', 'locale'))
FastGettext.text_domain = 'spider'
FastGettext.default_text_domain = 'spider'
l = Locale.current[0].to_s
l = $1 if l =~ /(\w\w)_+/
FastGettext.locale = l

module Spider
    
    module GetText
        
        # Executes a block of code in the given text_domain
        def self.in_domain(domain, &block)
            prev_text_domain = FastGettext.text_domain
            FastGettext.text_domain = domain if FastGettext.translation_repositories.key?(domain)
            v = yield
            FastGettext.text_domain = prev_text_domain
            v
        end

        # Sets the current text_domain; return the previous domain
        def self.set_domain(domain)
            prev_text_domain = FastGettext.text_domain
            FastGettext.text_domain = domain if FastGettext.translation_repositories.key?(domain)
            prev_text_domain
        end

        # Sets the current text_domain; assumes the domain was already set before, so skips any
        # check for domain validity
        def self.restore_domain(domain)
            FastGettext.text_domain = domain
        end
        
        def self.update_pofiles(textdomain, files, app_version, options = {})
            puts options.inspect if options[:verbose]
        
            #write found messages to tmp.pot
            temp_pot = "tmp.pot"
            ::GetText::Tools::XGetText.run("-o", temp_pot, *files)
        
            #merge tmp.pot and existing pot
            po_root = options.delete(:po_root) || "po"
            FileUtils.mkdir_p(po_root)
            ::GetText::Tools::MsgMerge.run("#{po_root}/#{textdomain}.pot", temp_pot, app_version, options.dup)
        
            #update local po-files
            only_one_language = options.delete(:lang)
            if only_one_language
              ::GetText::Tools::MsgMerge.run("#{po_root}/#{only_one_language}/#{textdomain}.po", temp_pot, app_version, options.dup)
            else
              Dir.glob("#{po_root}/*/#{textdomain}.po") do |po_file|
                ::GetText::Tools::MsgMerge.run(po_file, temp_pot, app_version, options.dup)
              end
            end
        
            File.delete(temp_pot)
          end







    end
    
end