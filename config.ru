$:.unshift(File.expand_path("../lib", __FILE__))
require 'espect/server'
run Espect::Server.new
