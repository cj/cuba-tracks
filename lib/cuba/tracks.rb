# deps
require 'cuba'
require 'cuba/render'
require "cuba/sugar/as"
require "rack/protection"
# tracks
require "cuba/tracks/version"
require "cuba/tracks/middleware"
# patches
require 'patch/cuba'
require "patch/cuba-sugar"

class Cuba::Tracks
  def self.app
    @app ||= Rack::Builder.new do
      use Middleware
    end
  end

  module Routes end

  if not env.mounted?
    require 'active_record'
    require 'action_mailer'
    require 'slim'
    require "tilt/coffee"
    require "tilt/sass"
  end

  require "#{root}/plugin/recursive_ostruct"

  autoload :ActiveRecordCuba , "#{root}/plugin/active_record"
  autoload :Assets           , "#{root}/plugin/assets"
  autoload :Auth             , "#{root}/plugin/auth"
  autoload :CommonPlugin     , "#{root}/plugin/common"
  autoload :Environment      , "#{root}/plugin/environment"
  autoload :FormBuilder      , "#{root}/plugin/form_builder"
  autoload :I18N             , "#{root}/plugin/i18n"
  autoload :S3DirectUpload   , "#{root}/plugin/s3_direct_upload"
  autoload :Widgets          , "#{root}/plugin/widgets"
  # ActionMailer
  # https://gist.github.com/acwright/1944639
  # DelayedJob
  # https://gist.github.com/robhurring/732327
  require "#{root}/config/application"

  Dir["#{root}/config/initializers/**/*.rb"].each  { |rb| require rb  }
  Dir["#{root}/app/widgets/**/*.rb"].each  { |rb| require rb  }

  require "#{root}/app/assets/assets"

  Dir["#{root}/app/routes/**/*.rb"].each  { |rb| require rb  }
  Dir["#{root}/app/presenters/**/*.rb"].each  { |rb| require rb  }
  Dir["#{root}/app/mailers/**/*.rb"].each  { |rb| require rb  }

  require "#{root}/config/routes"
end
