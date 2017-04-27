require 'yaml'
config_path = File.expand_path('../config.yml', __FILE__)
if File.exist?(config_path)
  config = YAML.load_file(config_path)
else
  config = {}
end

threads 5,5
if config['ssl_port']
  ssl_bind '0.0.0.0', config['ssl_port'] || 8899, {key: config['ssl_key'], cert: config['ssl_cert'], verify_mode: 'none'}
end
bind "tcp://0.0.0.0:#{config['port'] || 8898}"

prune_bundler
quiet false

if ENV['APP_ROOT']
  directory ENV['APP_ROOT']
end
