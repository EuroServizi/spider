module Spider; module Auth
    
    class SuperUser < LoginUser
        extend_model superclass, :add_polymorphic => true
        label _('Superuser'), _('Superusers')
        include LoginAuthenticator
        #campo che serve per renderlo anche un model per fare l'admin del cms
        element :global_admin, Bool

        def superuser?
            true
        end



    end
    
end; end