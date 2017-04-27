require 'base64'
require 'json'
require 'espect/message'

module Espect
  class Server

    def call(env)
      request = Rack::Request.new(env)
      case request.path
      when /\A\/inspect/
        decoded_body = Base64.decode64(request.body.read)
        message = Message.new(decoded_body)
        [200, {}, [message.to_json]]
      when /\A\/report\/([a-z]+)\z/
        [503, {}, ["Not implemented yet"]]
      else
        [200, {}, ["Welcome to Espect"]]
      end
    rescue =>e
      [500, {}, [{:error => e.class, :message => e.message, :backtrace => e.backtrace[0,5]}.to_json]]
    end

  end
end
