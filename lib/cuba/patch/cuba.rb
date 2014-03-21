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

    def console?
      ENV['CUBA_CONSOLE'] ? true : false
    end
  end

  module Render
    alias original_partial partial

    def view(template, locals = {}, layout = settings[:render][:layout])
      original_partial(layout, { content: original_partial(template, locals) }.merge(locals))
    end

    def partial template, locals = {}
      partial_template = template.gsub(/([a-zA-Z_]+)$/, '_\1')
      render(template_path(partial_template), locals, settings[:render][:options])
    end
  end
end
