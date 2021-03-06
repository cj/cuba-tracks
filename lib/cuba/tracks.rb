# deps
require 'cuba/render'
require "cuba/sugar"
require "rack/protection"
# patches
require 'cuba/patch/string'
require 'cuba/patch/cuba'
# tracks
class Cuba::Tracks < Cuba
end
require "cuba/tracks/version"
require "cuba/tracks/base"
require "cuba/tracks/middleware"

class Cuba::Tracks < Cuba
  extend Cuba::Tracks::Base::ClassMethods

  def self.app
    @app ||= Rack::Builder.new do
      use Middleware
    end
  end

  def self.initialize!
    settings[:root] = root

    # Initializers
    Dir["#{root}/config/initializers/**/*.rb"].each  { |rb| require rb  }

    # Permissions
    Dir["#{root}/app/models/permissions/**/*.rb"].each {|rb| require rb }
    Dir["#{root}/app/permissions/**/*.rb"].each {|rb| require rb }

    # Models
    Dir["#{root}/app/models/*/*.rb"].each {|rb| require rb }
    Dir["#{root}/app/models/**/*.rb"].each {|rb| require rb }

    # Forms
    Dir["#{root}/app/forms/*/*.rb"].each {|rb| require rb }
    Dir["#{root}/app/forms/**/*.rb"].each {|rb| require rb }

    # Assets
    require "#{root}/config/assets"

    # Presenters
    Dir["#{root}/app/presenters/**/*.rb"].each  { |rb| require rb  }

    # Mailers
    Dir["#{root}/app/mailers/**/*.rb"].each  { |rb| require rb  }

    # Routes
    Dir["#{root}/app/routes/**/*.rb"].each  { |rb| require rb  }
    require "#{root}/config/routes"
  end

  module Routes end

  if not env.mounted?
    require 'active_record'
    require 'action_mailer'
    require 'slim'
    require "tilt/coffee"
    require "tilt/sass"
  end

  require "cuba/plugin/recursive_ostruct"

  autoload :ActiveRecordCuba , "cuba/plugin/active_record"
  autoload :Assets           , "cuba/plugin/assets"
  autoload :Auth             , "cuba/plugin/auth"
  autoload :CommonPlugin     , "cuba/plugin/common"
  autoload :Environment      , "cuba/plugin/environment"
  autoload :FormBuilder      , "cuba/plugin/form_builder"
  autoload :I18N             , "cuba/plugin/i18n"
  autoload :S3DirectUpload   , "cuba/plugin/s3_direct_upload"
  autoload :Widgets          , "cuba/plugin/widgets"
  # ActionMailer
  # https://gist.github.com/acwright/1944639
  # DelayedJob
  # https://gist.github.com/robhurring/732327
end
