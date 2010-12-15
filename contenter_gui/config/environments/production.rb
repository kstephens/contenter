# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
unless ENV['RAILS_DONT_LOAD_CLASSES']
config.cache_classes = true
else
config.cache_classes = false
end

# more compact logs
config.log_level = :info

ENV['CONTENTER_ERROR_EMAIL_TO'] = nil # nil or empty to disable
ENV['CONTENTER_ERROR_EMAIL_SUBJECT'] = "[CMS PROD Error]"

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = true
# See:
#   http://github.com/rails/rails/commit/83e29b9773ac113ceacb1e36c2f333d692de2573
#   http://railsforum.com/viewtopic.php?id=23648
#config.action_view.cache_template_loading            = true

# Use a different cache store in production
# config.cache_store = :mem_cache_store

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

#  -- This section not yet tested --
# We use postfix, but sendmail is the correct AM option
ActionMailer::Base.delivery_method = :sendmail
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.raise_delivery_errors = false
ActionMailer::Base.default_charset = "iso-8859-1"
