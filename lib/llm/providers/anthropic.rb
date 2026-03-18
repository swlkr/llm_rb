# frozen_string_literal: true

require_relative "anthropic/media"
require_relative "anthropic/tools"
require_relative "anthropic/chat"
require_relative "anthropic/streaming"

module LLM
  module Providers
    class Anthropic < Provider
      include Media
      include Tools
      include Chat
      include Streaming

      def default_headers
        {
          "x-api-key" => config.anthropic_api_key,
          "anthropic-version" => "2023-06-01",
          "Content-Type" => "application/json"
        }
      end

      def base_url
        config.anthropic_api_base
      end
    end
  end
end
