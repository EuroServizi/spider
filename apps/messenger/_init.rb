Spider.load_app('core/admin')
Spider.load_app('worker')

module Spider

    module Messenger

        @description = ""
        @version = 0.1
        @path = File.dirname(__FILE__)
        @controller = :MessengerController
        include Spider::App

    end
    
    Spider::Admin.add(Messenger)
    
end

require 'apps/messenger/messenger'
require 'apps/messenger/controllers/messenger_controller'
require 'apps/messenger/controllers/mixins/messenger_helper'

Spider.conf.get('messenger.email.backends').each do |backend|
    require File.join('apps/messenger/backends/email/', backend)
end
Spider.conf.get('messenger.sms.backends').each do |backend|
    require File.join('apps/messenger/backends/sms/', backend)
end