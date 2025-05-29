 # frozen_string_literal: true
 
 module Admin
   class FeatureTogglesController < BaseController
     def update
       feature = params[:feature].to_sym
       actor = current_admin_user
       if Flipper.enabled?(feature, actor)
         Flipper.disable_actor(feature, actor)
         flash[:notice] = "#{feature.to_s.humanize} disabled"
       else
         Flipper.enable_actor(feature, actor)
         flash[:notice] = "#{feature.to_s.humanize} enabled"
       end
       redirect_back fallback_location: admin_root_path
     end
   end
 end