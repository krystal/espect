require 'yaml'

module Espect
  def self.config
    @config ||= begin
      config_path = File.expand_path('../../config.yml', __FILE__)
      if File.exist?(config_path)
        YAML.load_file(config_path)
      else
        {}
      end
    end
  end
end
