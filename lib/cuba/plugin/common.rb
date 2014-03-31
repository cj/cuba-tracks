module CommonPlugin
  class << self
    attr_accessor :app
  end

  def self.setup app
    self.app = app
  end

  def path_for url
    if CommonPlugin.app.mounted?
      "#{CommonPlugin.app.settings[:mounted_url]}/#{url}"
    else
      "/#{url}"
    end
  end
end
