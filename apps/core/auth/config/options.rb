module Spider
    
    config_option 'auth.enable_superuser_backdoor', _("Allow a backdoor for the superuser to login as any user"), :type => Spider::DataTypes::Bool,
        :default => false
    config_option 'auth.enable_auth_hub', "Se attivare l'autenticazione unica", :type => Spider::DataTypes::Bool, :default => false
    config_option 'auth.redirect_url_auth_hub', "Url redirect per fare auth unica", :type => String, :default => "https://start.soluzionipa.it/auth_hub"
    config_option 'auth.secret_auth_jwt', "Secret con cui criptare messaggi per token JWT", :type => String, :default => "6rg1e8r6t1bv8rt1r7y7b86d8fsw8fe6bg1t61v8vsdfs8erer6c18168"
end