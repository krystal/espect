require 'timeout'
require 'socket'
require 'espect'
require 'json'
require 'espect/spam_check'

module Espect
  class Message

    def initialize(message)
      @message = message
    end

    def spam_score
      scan_for_spam[0]
    end

    def spam_details
      scan_for_spam[1]
    end

    def threat?
      scan_for_threats[0]
    end

    def threat_message
      scan_for_threats[1]
    end

    def to_json
      to_hash.to_json
    end

    def to_hash
      {
        :spam_score => spam_score,
        :spam_details => spam_details.map(&:to_hash),
        :threat => threat?,
        :threat_message => threat_message
      }
    end

    private

    def scan_for_spam
      @spam_scan ||= begin
        data = nil
        Timeout.timeout(15) do
          tcp_socket = TCPSocket.new(Espect.config['spamd_host'] || '127.0.0.1', 783)
          tcp_socket.write("REPORT SPAMC/1.2\r\n")
          tcp_socket.write("Content-length: #{@message.bytesize}\r\n")
          tcp_socket.write("\r\n")
          tcp_socket.write(@message)
          tcp_socket.close_write
          data = tcp_socket.read
        end

        spam_checks = []
        total = 0.0
        rules = data ? data.split(/^---(.*)\r?\n/).last.split(/\r?\n/) : []
        while line = rules.shift
          if line =~ /\A([\- ]?[\d\.]+)\s+(\w+)\s+(.*)/
            total += $1.to_f
            spam_checks << SPAMCheck.new($2, $1.to_f, $3)
          else
            spam_checks.last.description << " " + line.strip
          end
        end

        [total.round(1), spam_checks]
      rescue Timeout::Error
        [0.0, [SPAMCheck.new("TIMEOUT", 0, "Timed out when scanning for spam")]]
      rescue => e
        puts "Error talking to spamd: #{e.class} (#{e.message})"
        puts e.backtrace[0,5]
        [0.0, [SPAMCheck.new("ERROR", 0, "Error when scanning for spam")]]
      ensure
        tcp_socket.close rescue nil
      end
    end

    def scan_for_threats
      @virus_result ||= begin
        data = nil
        Timeout.timeout(10) do
          tcp_socket = TCPSocket.new(Espect.config['clamav_host'] || '127.0.0.1', 2000)
          tcp_socket.write("zINSTREAM\0")
          tcp_socket.write([@message.bytesize].pack("N"))
          tcp_socket.write(@message)
          tcp_socket.write([0].pack("N"))
          tcp_socket.close_write
          data = tcp_socket.read
        end

        if data && data =~ /\Astream\:\s+(.*?)[\s\0]+?/
          if $1.upcase == 'OK'
            [false, "No threats found"]
          else
            [true, $1]
          end
        else
          [false, "Could not scan message"]
        end
      rescue Timeout::Error
        [false, "Timed out scanning for threats"]
      rescue => e
        puts "Error talking to clamav: #{e.class} (#{e.message})"
        puts e.backtrace[0,5]
        [false, "Error when scanning for threats"]
      ensure
        tcp_socket.close rescue nil
      end
    end

  end
end
