# frozen_string_literal: true

require_relative "gemini/media"
require_relative "gemini/tools"
require_relative "gemini/chat"
require_relative "gemini/streaming"
require_relative "gemini/images"

module LLM
  module Providers
    class Gemini < Provider
      include Media
      include Tools
      include Chat
      include Streaming
      include Images

      def default_headers
        { "Content-Type" => "application/json" }
      end

      def base_url
        config.gemini_api_base
      end
    end
  end
end
