# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.0.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|

  config.action_controller.session = {
    :session_key => '_app_session',
    :secret      => 'c4209f01d6515f782deb9a0f93634aed085dcef86aa9bc64ea71a80c22904859926b8f30cf3773e6ef42e3b06a589e3112c79209fc5c829d181ac9257aed360d'
  }

end

$LOAD_PATH.unshift "#{RAILS_ROOT}/../../../lib/"
require 'bleak_house'
