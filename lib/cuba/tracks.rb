# deps
require 'cuba/render'
require "rack/protection"
# tracks
require "cuba/tracks/version"
require "cuba/tracks/middleware"
# patches
require 'patch/string'
require 'patch/cuba'
require "patch/cuba-sugar"

class Cuba::Tracks < Cuba
  def self.app
    @app ||= Rack::Builder.new do
      use Middleware
    end
  end

  def self.initialize!
    require "plugin/recursive_ostruct"

    Dir["config/initializers/**/*.rb"].each  { |rb| require rb  }

    require "app/assets/assets"

    Dir["app/routes/**/*.rb"].each  { |rb| require rb  }
    Dir["app/presenters/**/*.rb"].each  { |rb| require rb  }
    Dir["app/mailers/**/*.rb"].each  { |rb| require rb  }

    require "config/routes"
  end

  $:.unshift root

  module Routes end

  if not env.mounted?
    require 'active_record'
    require 'action_mailer'
    require 'slim'
    require "tilt/coffee"
    require "tilt/sass"
  end

  autoload :ActiveRecordCuba , "plugin/active_record"
  autoload :Assets           , "plugin/assets"
  autoload :Auth             , "plugin/auth"
  autoload :CommonPlugin     , "plugin/common"
  autoload :Environment      , "plugin/environment"
  autoload :FormBuilder      , "plugin/form_builder"
  autoload :I18N             , "plugin/i18n"
  autoload :S3DirectUpload   , "plugin/s3_direct_upload"
  autoload :Widgets          , "plugin/widgets"
  # ActionMailer
  # https://gist.github.com/acwright/1944639
  # DelayedJob
  # https://gist.github.com/robhurring/732327
end
