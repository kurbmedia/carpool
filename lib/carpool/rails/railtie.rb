require 'carpool/mixins/action_controller'
require 'carpool/mixins/action_view'

module Carpool
  module Rails
    
    class Railtie < ::Rails::Railtie

      initializer :carpool do      
        ActionController::Base.class_eval do 
          include Carpool::Mixins::ActionController
        end
      end
      
      config.after_initialize do
        ActionView::Base.send :include, Carpool::Mixins::ActionView
      end
      
    end
    
  end
end