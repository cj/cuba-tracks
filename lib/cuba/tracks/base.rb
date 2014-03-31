module Cuba::Tracks::Base
  module ClassMethods
    def base_root; @base_root ||= Cuba.mounted?? Rails.root : '../../'; end
    def root; Cuba.mounted?? "#{Rails.root}/mounts/#{self.to_s.gsub('::App', '').underscore}" : Dir.pwd; end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end
end
