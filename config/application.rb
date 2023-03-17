# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'
require 'rack-cas/session_store/active_record'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ArclightOsu
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.rack_cas.server_url = ENV.fetch('CAS_URL', 'https://login.oregonstate.edu/cas')
    config.rack_cas.service = '/users/service' # If your user model isn't called User, change this
    config.rack_cas.session_store = RackCAS::ActiveRecordStore
  end
end
