require 'uri'
require 'net/https'
require "net/http"
require 'apps/cas_server/lib/utils'

# Encapsulates CAS functionality. This module is meant to be included in
# the CASServer::Controllers module.
module Spider; module CASServer::CAS

  include Spider::CASServer::Models
  
  class Error
      attr_reader :code, :message

      def initialize(code, message)
          @code = code
          @message = message
      end

      def to_s
          message
      end
  end
  
  def generate_ticket_string(prefix)
      saml = Spider.conf.get('cas.saml_compliant_tickets')
      if saml
          client_hostname = @request.env['HTTP_X_FORWARDED_FOR'] || @request.env['REMOTE_HOST'] || @request.env['REMOTE_ADDR']
          if saml == '1'
              "#{prefix[0..1]}#{client_hostname[0..19].ljust(20)}#{CASServer::Utils.random_string(20).ljust(20)}"
          elsif saml == '2'
              "#{prefix[0..1]}#{CASServer::Utils.random_string(20).ljust(20)}#{client_hostname}"
          elsif saml == '4'
              "#{prefix[0..1]}00#{client_hostname[0..19].ljust(20)}#{CASServer::Utils.random_string(20).ljust(20)}"
          end
      else
          "#{prefix}-#{CASServer::Utils.random_string}"
      end
  end

  def generate_login_ticket
    # 3.5 (login ticket)
    lt = LoginTicket.new
    lt.ticket = generate_ticket_string("LT")
    lt.client_hostname = @request.env['HTTP_X_FORWARDED_FOR'] || @request.env['REMOTE_HOST'] || @request.env['REMOTE_ADDR']
    lt.save
    $LOG.debug("Generated login ticket '#{lt.ticket}' for client" +
      " at '#{lt.client_hostname}'")
    lt
  end
  
  # Creates a TicketGrantingTicket for the given username. This is done when the user logs in
  # for the first time to establish their SSO session (after their credentials have been validated).
  #
  # The optional 'extra_attributes' parameter takes a hash of additional attributes
  # that will be sent along with the username in the CAS response to subsequent 
  # validation requests from clients.
  def generate_ticket_granting_ticket(username, extra_attributes = {})
    # 3.6 (ticket granting cookie/ticket)
    tgt = TicketGrantingTicket.new
    tgt.ticket = generate_ticket_string("TGC")
    tgt.username = username
    tgt.extra_attributes = extra_attributes
    tgt.client_hostname = @request.env['HTTP_X_FORWARDED_FOR'] || @request.env['REMOTE_HOST'] || @request.env['REMOTE_ADDR']
    tgt.save
    $LOG.debug("Generated ticket granting ticket '#{tgt.ticket}' for user" +
      " '#{tgt.username}' at '#{tgt.client_hostname}'" + 
      (extra_attributes.empty? ? "" : " with extra attributes #{extra_attributes.inspect}"))
    tgt
  end
  
  def generate_service_ticket(service, username, tgt)
    # 3.1 (service ticket)
    st = ServiceTicket.new
    st.ticket = generate_ticket_string("ST")
    st.service = service
    st.username = username
    st.ticket_granting_ticket = tgt
    st.client_hostname = @request.env['HTTP_X_FORWARDED_FOR'] || @request.env['REMOTE_HOST'] || @request.env['REMOTE_ADDR']
    st.save

    unless service.blank?
      service_and_params = service.split('?')
      if service_and_params.length > 1
        servizio = CGI::parse(service_and_params[1])['servizio']
        servizio = servizio.first unless servizio.blank?
      end
    end

    #vedo se l'username viene da federa, ricavo il cf che uso per cercare l'id dell'utente portale
    if (username.strip =~ /^federa_emilia_/) == 0 and !defined?(::Portal::UtenteFederaEmiliaRomagna).nil?
      $LOG.debug("Entrato con Federa")
      #caso utente con accesso federa
      chiave_utente = username.strip.gsub('federa_emilia_romagana','')
      chiave_utente_maiuscolo = chiave_utente.upcase
      utente_federa = ::Portal::UtenteFederaEmiliaRomagna.where{ |ut_fed| (ut_fed.chiave == chiave_utente) | (ut_fed.chiave == chiave_utente_maiuscolo) }
      utente_portale = utente_federa.last.utente_portale
      #salvo la traccia sulla tabella del portale
      unless utente_portale.blank?
        ::Portal::Traccia.salva_traccia(st.client_hostname, "#{servizio}", utente_portale , { 'provider_accesso' => 'Federa Emilia Romagna' }.to_json , nil , 'cas', nil) 
      end
      
    elsif (username.strip =~ /^spid_/) == 0 and !defined?(::Portal::UtenteSpidAgid).nil?
      $LOG.debug("Entrato con SPID")
      #caso utente con accesso spid
      chiave_utente = username.strip.gsub('spid_','')
      chiave_utente_maiuscolo = chiave_utente.upcase
      utente_spid = ::Portal::UtenteSpidAgid.where{ |ut_spid| (ut_spid.chiave == chiave_utente) | (ut_spid.chiave == chiave_utente_maiuscolo) }
      utente_portale = utente_spid.last.utente_portale unless utente_spid.last.blank?
      unless utente_portale.blank?
        ::Portal::Traccia.salva_traccia(st.client_hostname, "#{servizio}", utente_portale , { 'provider_accesso' => 'SPID' }.to_json , nil , 'cas', nil)
      end
      
    else
      $LOG.debug("Entrato con auth interna")
      #utente con auth interna
      #controllo che non abbia uno degli altri auth_provider esterni
      username_utente = username.strip
      utente_portale = ::Portal::Utente.where{|ut| ut.utente_login.username == username_utente}
      #cerco l'username in utente_login
      unless utente_portale.blank?
        ::Portal::Traccia.salva_traccia(st.client_hostname, "#{servizio}", utente_portale.last , { 'provider_accesso' => 'Autenticazione interna' }.to_json , nil , 'cas', nil)
      else
        #altro accesso...non fatto
      end
      
    end
    
    



    $LOG.debug("Generated service ticket '#{st.ticket}' for service '#{st.service}'" +
      " for user '#{st.username}' at '#{st.client_hostname}'")
    st
  end
  
  def generate_proxy_ticket(target_service, pgt)
    # 3.2 (proxy ticket)
    pt = ProxyTicket.new
    pt.ticket = generate_ticket_string("PT")
    pt.service = target_service
    pt.username = pgt.service_ticket.username
    pt.proxy_granting_ticket_id = pgt.id
    pt.ticket_granting_ticket = pgt.service_ticket.ticket_granting_ticket
    pt.client_hostname = @request.env['HTTP_X_FORWARDED_FOR'] || @request.env['REMOTE_HOST'] || @request.env['REMOTE_ADDR']
    pt.save
    $LOG.debug("Generated proxy ticket '#{pt.ticket}' for target service '#{pt.service}'" +
      " for user '#{pt.username}' at '#{pt.client_hostname}' using proxy-granting" +
      " ticket '#{pgt.ticket}'")
    pt
  end
  
  def generate_proxy_granting_ticket(pgt_url, st)
    uri = URI.parse(pgt_url)
    https = Net::HTTP.new(uri.host,uri.port)
    https.use_ssl = true
    
    # Here's what's going on here:
    # 
    #   1. We generate a ProxyGrantingTicket (but don't store it in the database just yet)
    #   2. Deposit the PGT and it's associated IOU at the proxy callback URL.
    #   3. If the proxy callback URL responds with HTTP code 200, store the PGT and return it;
    #      otherwise don't save it and return nothing.
    #      
    https.start do |conn|
      path = uri.path.empty? ? '/' : uri.path
      
      pgt = ProxyGrantingTicket.new
      pgt.ticket = "PGT-" + CASServer::Utils.random_string(60)
      pgt.iou = "PGTIOU-" + CASServer::Utils.random_string(57)
      pgt.service_ticket_id = st.id
      pgt.client_hostname = @request.env['HTTP_X_FORWARDED_FOR'] || @request.env['REMOTE_HOST'] || @request.env['REMOTE_ADDR']
      
      # FIXME: The CAS protocol spec says to use 'pgt' as the parameter, but in practice
      #         the JA-SIG and Yale server implementations use pgtId. We'll go with the
      #         in-practice standard.
      path += (uri.query.nil? || uri.query.empty? ? '?' : '&') + "pgtId=#{pgt.ticket}&pgtIou=#{pgt.iou}"
      
      response = conn.request_get(path)
      # TODO: follow redirects... 2.5.4 says that redirects MAY be followed
      
      if response.code.to_i == 200
        # 3.4 (proxy-granting ticket IOU)
        pgt.save
        $LOG.debug "PGT generated for pgt_url '#{pgt_url}': #{pgt.inspect}"
        pgt
      else
        $LOG.warn "PGT callback server responded with a bad result code '#{response.code}'. PGT will not be stored."
      end
    end
  end
  
  def validate_login_ticket(ticket)
    $LOG.debug("Validating login ticket '#{ticket}'")
  
    success = false
    if ticket.nil?
      error = "Your login request did not include a login ticket. There may be a problem with the authentication system."
      $LOG.warn("Missing login ticket.")
    elsif lt = LoginTicket.load(:ticket => ticket)
      if lt.consumed
        error = "The login ticket you provided has already been used up. Please try logging in again."
        $LOG.warn("Login ticket '#{ticket}' previously used up")
      elsif lt.obj_created && (DateTime.now - lt.obj_created) < Spider.conf.get('cas.login_ticket_expiry')
        $LOG.info("Login ticket '#{ticket}' successfully validated")
      else
        error = "Your login ticket has expired. Please try logging in again."
        $LOG.warn("Expired login ticket '#{ticket}'")
      end
    else
      error = "The login ticket you provided is invalid. Please try logging in again."
      $LOG.warn("Invalid login ticket '#{ticket}'")
    end
    
    lt.consume! if lt
    
    error
  end
  
  def validate_ticket_granting_ticket(ticket)
    $LOG.debug("Validating ticket granting ticket '#{ticket}'")
  
    if ticket.nil?
      error = "No ticket granting ticket given."
      $LOG.debug(error)
    elsif tgt = TicketGrantingTicket.load(:ticket => ticket)
      if Spider.conf.get('cas.expire_sessions') && DateTime.now - tgt.obj_created > Spider.conf.get('cas.ticket_granting_ticket_expiry')
        error = "Your session has expired. Please log in again."
        $LOG.info("Ticket granting ticket '#{ticket}' for user '#{tgt.username}' expired.")
      else
        $LOG.info("Ticket granting ticket '#{ticket}' for user '#{tgt.username}' successfully validated.")
      end
    else
      error = "Invalid ticket granting ticket '#{ticket}' (no matching ticket found in the database)."
      $LOG.warn(error)
    end
    
    [tgt, error]
  end

  def validate_service_ticket(service, ticket, allow_proxy_tickets = false, allow_nil_service=false)
    $LOG.debug("Validating service/proxy ticket '#{ticket}' for service '#{service}'")
  
    if (service.nil? && !allow_nil_service) or ticket.nil?
      error = Error.new(:INVALID_REQUEST, "Ticket or service parameter was missing in the request.")
      $LOG.warn("#{error.code} - #{error.message}")
    elsif st = ServiceTicket.load(:ticket => ticket)
      if st.consumed
        error = Error.new(:INVALID_TICKET, "Ticket '#{ticket}' has already been used up.")
        $LOG.warn("#{error.code} - #{error.message}")
      elsif st.kind_of?(CASServer::Models::ProxyTicket) && !allow_proxy_tickets
        error = Error.new(:INVALID_TICKET, "Ticket '#{ticket}' is a proxy ticket, but only service tickets are allowed here.")
        $LOG.warn("#{error.code} - #{error.message}")
      elsif DateTime.now - st.obj_created > Spider.conf.get('cas.service_ticket_expiry')
        error = Error.new(:INVALID_TICKET, "Ticket '#{ticket}' has expired.")
        $LOG.warn("Ticket '#{ticket}' has expired.")
      elsif service && !st.matches_service?(service)
        error = Error.new(:INVALID_SERVICE, "The ticket '#{ticket}' belonging to user '#{st.username}' is valid,"+
          " but the requested service '#{service}' does not match the service '#{st.service}' associated with this ticket.")
        $LOG.warn("#{error.code} - #{error.message}")
      else
        $LOG.info("Ticket '#{ticket}' for service '#{service}' for user '#{st.username}' successfully validated.")
      end
    else
      error = Error.new(:INVALID_TICKET, "Ticket '#{ticket}' not recognized.")
      $LOG.warn("#{error.code} - #{error.message}")
    end
    
    if st
      st.consume!
    end
    
    
    [st, error]
  end
  
  def validate_proxy_ticket(service, ticket)
    pt, error = validate_service_ticket(service, ticket, true)
    
    if pt.kind_of?(CASServer::Models::ProxyTicket) && !error
      if not pt.proxy_granting_ticket
        error = Error.new(:INTERNAL_ERROR, "Proxy ticket '#{pt}' belonging to user '#{pt.username}' is not associated with a proxy granting ticket.")
      elsif not pt.proxy_granting_ticket.service_ticket
        error = Error.new(:INTERNAL_ERROR, "Proxy granting ticket '#{pt.proxy_granting_ticket}'"+
          " (associated with proxy ticket '#{pt}' and belonging to user '#{pt.username}' is not associated with a service ticket.")
      end
    end
    
    [pt, error]
  end
  
  def validate_proxy_granting_ticket(ticket)
    if ticket.nil?
      error = Error.new(:INVALID_REQUEST, "pgt parameter was missing in the request.")
      $LOG.warn("#{error.code} - #{error.message}")
    elsif pgt = ProxyGrantingTicket.load(:ticket => ticket)
      if pgt.service_ticket
        $LOG.info("Proxy granting ticket '#{ticket}' belonging to user '#{pgt.service_ticket.username}' successfully validated.")
      else
        error = Error.new(:INTERNAL_ERROR, "Proxy granting ticket '#{ticket}' is not associated with a service ticket.")
        $LOG.error("#{error.code} - #{error.message}")
      end
    else
      error = Error.new(:BAD_PGT, "Invalid proxy granting ticket '#{ticket}' (no matching ticket found in the database).")
      $LOG.warn("#{error.code} - #{error.message}")
    end
    
    [pgt, error]
  end
  
  # Takes an existing ServiceTicket object (presumably pulled from the database)
  # and sends a POST with logout information to the service that the ticket
  # was generated for.
  #
  # This makes possible the "single sign-out" functionality added in CAS 3.1.
  # See http://www.ja-sig.org/wiki/display/CASUM/Single+Sign+Out
  def send_logout_notification_for_service_ticket(st)
    uri = URI.parse(st.service)
    http = Net::HTTP.new(uri.host, uri.port)
    #http.use_ssl = true if uri.scheme = 'https'
    
    time = Time.now
    rand = CASServer::Utils.random_string
    
    path = uri.path
    path = '/' if path.empty?
    
    url_logout_cas = Spider.conf.get('cas.url_logout_cas')
    path = url_logout_cas unless url_logout_cas.blank?

    req = Net::HTTP::Post.new(path)
    str_saml_logout =  %{<samlp:LogoutRequest ID="#{rand}" Version="2.0" IssueInstant="#{time.rfc2822}">
      <saml:NameID></saml:NameID>
      <samlp:SessionIndex>#{st.ticket}</samlp:SessionIndex>
      </samlp:LogoutRequest>}
    
    Spider.logger.debug "*** Logout saml#{str_saml_logout}"
    req.set_form_data(
      'logoutRequest' => str_saml_logout
      )
    
    http.start do |conn|
      response = conn.request(req)
            
      if response.kind_of? Net::HTTPSuccess
        $LOG.info "Logout notification successfully posted to #{st.service.inspect}."
        return true
      else
        $LOG.error "Service #{st.service.inspect} responed to logout notification with code '#{response.code}'!"
        return false
      end
    end
  end
  
  def service_uri_with_ticket(service, st, saml=false)
    raise ArgumentError, "Second argument must be a ServiceTicket!" unless st.kind_of? CASServer::Models::ServiceTicket
    
    # This will choke with a URI::InvalidURIError if service URI is not properly URI-escaped...
    # This exception is handled further upstream (i.e. in the controller).
    service_uri = URI.parse(service)
    
    if service.include? "?"
      if service_uri.query.empty?
        query_separator = ""
      else
        query_separator = "&"
      end
    else
      query_separator = "?"
    end
    
    service_with_ticket = service + query_separator
    if saml
        service_with_ticket += 'SAMLart='
    else
        service_with_ticket += "ticket=" 
    end
    service_with_ticket += st.ticket
    service_with_ticket
  end
  
  # Strips CAS-related parameters from a service URL and normalizes it,
  # removing trailing / and ?. Also converts any spaces to +.
  #
  # For example, "http://google.com?ticket=12345" will be returned as
  # "http://google.com". Also, "http://google.com/" would be returned as
  # "http://google.com".
  #
  # Note that only the first occurance of each CAS-related parameter is
  # removed, so that "http://google.com?ticket=12345&ticket=abcd" would be
  # returned as "http://google.com?ticket=abcd".
  def clean_service_url(dirty_service)
    return dirty_service if dirty_service.nil? || dirty_service.empty?
    clean_service = dirty_service.dup
    ['service', 'ticket', 'gateway', 'renew'].each do |p|
      clean_service.sub!(Regexp.new("#{p}=[^&]*"), '')
    end
    
    clean_service.gsub!(/[\/\?]$/, '')
    clean_service.gsub!(' ', '+')
    
    $LOG.debug("Cleaned dirty service URL #{dirty_service.inspect} to #{clean_service.inspect}") if
      dirty_service != clean_service
      
    return clean_service
  end
  module_function :clean_service_url
  
end; end
