class Cuba::Tracks
  class Middleware
    class << self
    # taken from
    # https://github.com/rkh/rack-protection/blob/master/lib/rack/protection.rb#L20
      def new app, options = {}
        # except    = Array options[:except]
        # use_these = Array options[:use]
        Rack::Builder.new do
          use Rack::Session::Cookie, secret: ENV['SECRET_BASE_KEY']
          # we need to disable session_hijacking because IE uses different headers
          # for ajax request over standard ones.
          # https://github.com/rkh/rack-protection/issues/11#issuecomment-9005539
          use Rack::Protection, except: :session_hijacking

          if not Cuba.env.mounted? and Cuba.env.development?
            require 'rack-livereload'
            use Rack::LiveReload
            use Rack::Reloader
          end

          if Cuba.env.test? or Cuba.env.development?
            use PryRescue::Rack
          end
          # continue running the application
          run app
        end.to_app
      end
    end
  end
end
