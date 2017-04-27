$:.unshift(File.expand_path('../../lib', __FILE__))
require 'espect/message'
message = Espect::Message.new(File.read(File.expand_path("../virus-message.msg", __FILE__)))
puts message.to_json
