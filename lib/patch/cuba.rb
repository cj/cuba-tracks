class Cuba
  class << self
    attr_accessor :root

    def env
      @env ||= EnvString.new(
        ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'
      )
    end

    def root= path
      @root = path
    end

    def root
      @root ||= Dir.getwd
    end

    # backwards compatibility
    def mounted?
      env.mounted?
    end

    def settings= settings
      @settings = settings
    end
  end

  class EnvString < String
    [:production, :development, :test, :staging].each do |env|
      define_method "#{env}?" do
        self == env.to_s
      end
    end

    def mounted?
      defined?(::Rails) ? true : false
    end
  end
end
