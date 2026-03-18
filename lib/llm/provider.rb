# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module LLM
  class Provider
    attr_reader :config

    def initialize(config)
      @config = config
      @connections = {}
      @mutex = Mutex.new
    end

    def complete(messages, model:, tools: nil, schema: nil, temperature: nil, stream: nil, &block)
      raise NotImplementedError
    end

    def paint(prompt, model:, size: nil)
      raise NotImplementedError
    end

    private

    def post(url, body, headers: {}, stream: false, &block)
      uri = URI.parse(url)
      request = Net::HTTP::Post.new(uri.request_uri)
      request.body = JSON.generate(body)
      request["Content-Type"] = "application/json"
      headers.each { |k, v| request[k] = v }

      if stream && block_given?
        execute_streaming_request(uri, request, &block)
      else
        execute_request(uri, request)
      end
    end

    def get(url, headers: {})
      uri = URI.parse(url)
      request = Net::HTTP::Get.new(uri.request_uri)
      headers.each { |k, v| request[k] = v }
      execute_request(uri, request)
    end

    def execute_request(uri, request, retries: 0)
      conn = connection_for(uri)
      response = conn.request(request)
      handle_error!(response) unless response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET, EOFError => e
      if retries < config.max_retries
        sleep(2**retries * 0.5)
        @mutex.synchronize { @connections.delete("#{uri.host}:#{uri.port}") }
        execute_request(uri, request, retries: retries + 1)
      else
        raise Error, "Request failed after #{config.max_retries} retries: #{e.message}"
      end
    end

    def execute_streaming_request(uri, request, &block)
      conn = connection_for(uri)
      conn.request(request) do |response|
        handle_error!(response) unless response.is_a?(Net::HTTPSuccess)
        parse_sse(response, &block)
      end
    end

    def parse_sse(response, &block)
      buffer = +""
      response.read_body do |chunk|
        buffer << chunk
        while (idx = buffer.index("\n\n"))
          event_text = buffer.slice!(0, idx + 2)
          event_text.each_line do |line|
            line.strip!
            next if line.empty?
            if line.start_with?("data: ")
              data = line[6..]
              next if data == "[DONE]"
              begin
                parsed = JSON.parse(data)
                block.call(parsed)
              rescue JSON::ParserError
                next
              end
            end
          end
        end
      end
      # Process remaining buffer
      unless buffer.strip.empty?
        buffer.each_line do |line|
          line.strip!
          next if line.empty?
          if line.start_with?("data: ")
            data = line[6..]
            return if data == "[DONE]"
            begin
              parsed = JSON.parse(data)
              block.call(parsed)
            rescue JSON::ParserError
              next
            end
          end
        end
      end
    end

    def connection_for(uri)
      key = "#{uri.host}:#{uri.port}"
      @mutex.synchronize do
        conn = @connections[key]
        if conn && conn.started?
          return conn
        end

        conn = if config.http_proxy
                 proxy_uri = URI.parse(config.http_proxy)
                 Net::HTTP.new(uri.host, uri.port, proxy_uri.host, proxy_uri.port,
                               proxy_uri.user, proxy_uri.password)
               else
                 Net::HTTP.new(uri.host, uri.port)
               end

        if uri.scheme == "https"
          conn.use_ssl = true
        end

        conn.open_timeout = config.request_timeout
        conn.read_timeout = config.request_timeout
        conn.keep_alive_timeout = 30
        conn.start
        @connections[key] = conn
        conn
      end
    end

    def handle_error!(response)
      status = response.code.to_i
      body = begin
        JSON.parse(response.body)
      rescue
        response.body
      end

      message = extract_error_message(body)

      # Check for context length exceeded
      if status == 400 && message.to_s.match?(/context.length|token.limit|too.long|max.*token/i)
        raise ContextLengthExceededError.new(message, status: status, body: body)
      end

      error_class = ERROR_MAP[status] || Error
      raise error_class.new(message, status: status, body: body)
    end

    def extract_error_message(body)
      case body
      when Hash
        body.dig("error", "message") || body["error"] || body["message"] || body.to_s
      else
        body.to_s
      end
    end
  end
end
