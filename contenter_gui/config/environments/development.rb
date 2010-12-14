# Settings specified here will take precedence over those in config/environment.rb

# This convenience is gone due to a Rails bug
# http://www.theirishpenguin.com/2009/01/22/bug-of-the-day-nilinclude-error-with-create_time_zone_conversion_attribute/
# config.cache_classes = true
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

ENV['CONTENTER_ERROR_EMAIL_TO'] = "root@localhost"  # nil or empty to disable
ENV['CONTENTER_ERROR_EMAIL_SUBJECT'] = "[CMS Dev Error]"
# ENV['CONTENTER_ERROR_EMAIL_BODY'] =  "[:time => Time.now]" # TODO place an evalable chunk in here to override the default

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = false

# Don't care if the mailer can't send in prod, but show us errors in dev
config.action_mailer.raise_delivery_errors = true
ActionMailer::Base.delivery_method = :sendmail
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.raise_delivery_errors = false
ActionMailer::Base.default_charset = "iso-8859-1"

require 'ruby-debug'

