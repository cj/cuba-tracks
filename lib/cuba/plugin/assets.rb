module Assets
  class << self
    attr_accessor :app
  end

  def self.setup app
    self.app = app

    require 'mimemagic'
    require 'base64'
    require 'slim'
    require 'sass'
    require 'ostruct'

    # if ENV['RACK_ENV'] != 'production'
    #   require 'rugged'
    # end

    Slim::Engine.set_default_options \
      disable_escape: true,
      use_html_safe: true,
      disable_capture: false,
      pretty: (app.env.production? or app.env.staging?) ? false : true

    app.settings[:assets] ||= OpenStruct.new({
      settings: {},
      css: [],
      images: [],
      js_head: [],
      js: []
    })
  end

  %w(css image js js_head).each do |type|
    define_method "#{type}_assets" do
      plugin[:"#{type}"]
    end
  end

  def asset_path file
    case file[/(\.[^.]+)$/]
    when '.css', '.js'
      path = "#{plugin.settings[:path] || '/'}#{cache_string}assets/#{file}"
    else
      path = "#{plugin.settings[:path] || '/'}#{cache_string}assets/images/#{file}"
    end
    "http#{req.env['SERVER_PORT'] == '443' ? 's' : ''}://#{req.env['HTTP_HOST']}#{path}"
  end

  def image_tag file, options = {}
    options[:src] = asset_path(file)
    mab do
      img options
    end
  end

  def fa_icon icon, options = {}
    options[:class] ||= ''
    options[:class] += " fa fa-#{icon}"

    mab do
      i options
    end
  end

  def accepted_assets
    "(.*)\.(js|css|eot|svg|ttf|woff|png|gif|jpg|jpeg)$"
  end

  private

  def cache_string
    if Cuba.env.production?
      # @cache_string ||= (File.read "#{Assets.app.root}/sha") + "/"
    end
  end

  def plugin
    Assets.app.settings[:assets]
  end

  module ClassMethods
    %w(css image js js_head).each do |type|
      define_method "#{type}_assets" do |files|
        files.each do |path|
          settings[:assets][:"#{type}"] << path
        end
      end
    end

    def all_assets
      settings[:assets]
    end

    def assets_settings as
      settings[:assets].settings.merge! as
    end
  end

  class Routes < Struct.new(:settings)
    def app
      App.settings = settings
      App.root = settings[:root]
      App.plugin Cuba::Render
      App.plugin Assets
      App
    end
  end

  class App < Cuba
    define do
      on get, accepted_assets do |file, ext|
        res.headers["Content-Type"] = "#{MimeMagic.by_extension(ext).to_s}; charset=utf-8"

        if file[/bower/]
          if ext == 'css' and css_assets.include? file + '.scss'
            res.write render "#{Assets.app.root}/app/assets/#{file}.scss"
          elsif js_assets.include? file + '.coffee' or js_head_assets.include? file + '.coffee'
            res.write render "#{Assets.app.root}/app/assets/#{file}.coffee"
          else
            res.write File.read "#{Assets.app.root}/app/assets/#{file}.#{ext}"
          end
        else
          case ext
          when 'css'
            if css_assets.include? file + '.scss'
              res.write render "#{Assets.app.root}/app/assets/stylesheets/#{file}.scss"
            else
              res.write File.read "#{Assets.app.root}/app/assets/stylesheets/#{file}.#{ext}"
            end
          when 'js'
            if js_assets.include? file + '.coffee'or js_head_assets.include? file + '.coffee'
              res.write render "#{Assets.app.root}/app/assets/javascripts/#{file}.coffee"
            else
              res.write File.read "#{Assets.app.root}/app/assets/javascripts/#{file}.#{ext}"
            end
          else
            res.write File.read "#{Assets.app.root}/app/assets/#{file}.#{ext}"
          end
        end
      end
    end
  end
end
