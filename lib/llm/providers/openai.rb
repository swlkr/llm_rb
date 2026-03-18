# frozen_string_literal: true

require_relative "openai/media"
require_relative "openai/tools"
require_relative "openai/chat"
require_relative "openai/streaming"
require_relative "openai/images"

module LLM
  module Providers
    class OpenAI < Provider
      include Media
      include Tools
      include Chat
      include Streaming
      include Images

      def default_headers
        {
          "Authorization" => "Bearer #{config.openai_api_key}",
          "Content-Type" => "application/json"
        }
      end

      def base_url
        config.openai_api_base
      end
    end
  end
end
