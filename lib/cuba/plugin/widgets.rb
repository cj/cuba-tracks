require "observer"

module Widgets
  class << self
    attr_accessor :app
  end

  def self.setup app
    self.app = app
    app.settings[:widgets] ||= {}
    app.plugin Cuba::Sugar

    Dir["#{app.root}/app/widgets/**/*.rb"].each  { |rb| require rb  }
  end

  def widgets list = false
    widget_name, incoming_event, event = load_widgets

    if incoming_event
      res.headers["Content-Type"] = "text/javascript; charset=utf-8"
      event.trigger incoming_event.to_sym, widget_name, req.params
      res.write "$('head > meta[name=csrf-token]').attr('content', '#{csrf_token}');"
      res.write '$(document).trigger("page:change");'
    end

    true
  end

  def widgets_root
    settings[:widgets_root]
  end

  def render_widget *args
    load_widgets unless req.env[:loaded_widgets]

    if args.first.kind_of? Hash
      opts = args.first
      name = req.env[:widget_name]
    else
      name = args.first
      opts = args.length > 1 ? args.last : {}
    end

    # set the current state (the method that will get called on render_widget)
    state = opts[:state] || 'display'

    widget = req.env[:loaded_widgets][name]

    if widget.method(state).parameters.length > 0
      widget.send state, opts
    else
      widget.send state
    end
  end
  alias_method :widget_render, :render_widget

  def widget_div opts = {}, &block
    defaults = {
      id: "#{req.env[:widget_name]}_#{req.env[:widget_state]}"
    }.merge opts

    name = req.env[:widget_name]
    widget = req.env[:loaded_widgets][name]

    html = block.call(widget)

    mab do
      div defaults do
        text! html
      end
    end
  end

  def url_for_event event, options = {}
    widget_name = req.env[:widget_name]
    "#{path_for('widgets')}?widget_event=#{event}&widget_name=#{widget_name}&" + URI.encode_www_form(options)
  end

  def load_widgets
    req.env[:loaded_widgets] ||= {}

    event = Events.new res, req, settings

    if incoming_event = req.params["widget_event"]
      widget_name = req.params["widget_name"]
      opts = { from_event: true }
    else
      opts = {}
    end

    settings[:widgets].each do |name, widget|
      req.env[:loaded_widgets][name] = widget.new(self, res, req, settings, event, name, opts)
    end

    [widget_name, incoming_event, event]
  end

  module ClassMethods
    def has_widgets *list
      list.each do |widget|
        settings[:widgets].merge! widget
      end
    end

    def widgets_root= path
      settings[:widgets_root] = path
    end

    def widgets_root
      settings[:widgets_root]
    end
  end

  class Events < Struct.new(:res, :req, :settings)
    include Observable

    def trigger event, widget_name, user_data = {}
      # data = OpenStruct.new({
      #   settings: settings,
      #   data: user_data
      # })
      data = user_data.to_ostruct

      # THIS IS WHAT WILL MAKE SURE EVENTS ARE TRIGGERED
      changed
      ##################################################

      notify_observers event, widget_name, data
    end
  end

  class Base
    JS_ESCAPE = { '\\' => '\\\\', '</' => '<\/', "\r\n" => '\n', "\n" => '\n', "\r" => '\n', '"' => '\\"', "'" => "\\'" }
    attr_accessor :app, :res, :req, :settings, :event, :folder, :options

    def initialize app, res, req, settings, event, folder, options
      @app      = app
      @res      = res
      @req      = req
      @settings = settings
      @event    = event
      @folder   = folder
      @options  = options

      # add the widget to the req widgets
      req.env[:widgets] ||= {}
      unless req.env[:widgets][folder]
        req.env[:widgets][folder] = {}
      end

      event.add_observer self, :trigger_event
    end

    def current_user
      app.current_user
    end

    def id_for state
      "#{req.env[:widget_name]}_#{state}"
    end

    def page_change
      res.headers["Content-Type"] = "text/javascript; charset=utf-8"
      res.write '$(document).trigger("page:change");'
    end

    def replace state, opts = {}
      @options[:replace] = true

      if !state.is_a? String
        content = render state, opts
        selector = '#' + id_for(state)
      else
        if !opts.key?(:content) and !opts.key?(:with)
          content = render opts
        else
          content = opts[:content] || opts[:with]
        end
        selector = state
      end

      res.write '$("' + selector + '").replaceWith("' + escape(content) + '");'
      # scroll to the top of the page just as if we went to the url directly
      res.write 'window.scrollTo(0, 0);'
    end

    def hide selector
      res.write '$("' + selector + '").hide();'
    end

    def append selector, opts = {}
      content = render opts
      res.write '$("' + selector + '").append("'+ escape(content) +'");'
    end

    def add_after selector, opts = {}
      content = render opts
      res.write '$("' + selector + '").after("'+ escape(content) +'");'
    end

    def attrs_for selector, opts = {}
      res.write '$("' + selector + '").attr('+ (opts.to_json) +');'
    end

    def escape js
      js.to_s.gsub(/(\\|<\/|\r\n|\\3342\\2200\\2250|[\n\r"'])/) {|match| JS_ESCAPE[match] }
    end

    def trigger_event event, widget_name, data = {}
      if events = self.class.events
        events.each do |class_event, opts|
          if class_event == event && (widget_name == folder.to_s or opts[:for].to_s == widget_name)
            event = opts[:with] if opts[:with]

            if method(event).parameters.length > 0
              send(event, data)
            else
              send(event)
            end
          end
        end
      end
    end

    def render *args
      if args.first.kind_of? Hash
        locals = args.first
        # if it's a partial we add an underscore infront of it
        state = view = locals[:state] || "#{locals[:partial]}".gsub(/([a-zA-Z_]+)$/, '_\1')
      else
        state = view = args.first
        locals = args.length > 1 ? args.last : {}
      end

      unless view
        state = view = caller[0][/`.*'/][1..-2]

        if (options.key?(:from_event) and !options.key?(:replace))
          @options[:cache] = false
        end
      end

      if locals.key?(:state) and state.to_s == view
        return send state
      end

      tmpl_engine = settings[:render][:template_engine]

      if (req_helper_methods = req.env[:widgets][folder][:req_helper_methods]) \
      and (!options.key?(:cache))
        locals.merge! req_helper_methods
      else
        req.env[:widgets][folder][:req_helper_methods] = {}

        helper_methods.each do |method|
          req.env[:widgets][folder][:req_helper_methods][method] = locals[method] = self.send method
        end
      end

      req.env[:widget_name]  = folder
      req.env[:widget_state] = state

      locals[:w] = locals[:widget] = self

      app.render "#{app.widgets_root}/#{folder}/#{view}.#{tmpl_engine}", locals
    end

    private

    def helper_methods
      self.class.available_helper_methods || []
    end

    class << self
      attr_accessor :events, :available_helper_methods

      def respond_to event, opts = {}
        @events ||= []
        @events << [event, opts]
      end

      def responds_to *events
        @events ||= []
        events.each do |event|
          @events << [event, {}]
        end
      end

      def helper_method method
        @available_helper_methods ||= []
        @available_helper_methods << method
      end

      def helper_methods *methods
        methods.each do |method|
          helper_method method
        end
      end
    end
  end

  class Routes < Struct.new(:settings)
    def app
      App.settings = settings
      App.plugin Cuba::Render
      App.plugin Auth
      App.plugin Assets
      App.plugin CommonPlugin
      App.plugin Cuba::I18N
      App.plugin FormBuilder
      App.plugin Widgets

      App
    end
  end

  class App < Cuba
    define do
      on(default, widgets) {}
    end
  end
end
