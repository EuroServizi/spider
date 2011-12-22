module Spider; module Admin

    class AppAdminController < Spider::PageController

        def before(action='', *params)
            @scene.admin_breadcrumb ||= []
            unless @_did_breadcrumb
                @scene.admin_breadcrumb << {:url => self.class.http_url, :label => self.class.app.full_name}
            end
            @_did_breadcrumb = true
            super
        end

    end

end; end
