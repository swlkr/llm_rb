# frozen_string_literal: true

module LLM
  class Configuration
    attr_accessor :openai_api_key, :openai_api_base,
                  :anthropic_api_key, :anthropic_api_base,
                  :gemini_api_key, :gemini_api_base,
                  :request_timeout, :max_retries, :http_proxy

    def initialize
      @openai_api_key = nil
      @openai_api_base = "https://api.openai.com"
      @anthropic_api_key = nil
      @anthropic_api_base = "https://api.anthropic.com"
      @gemini_api_key = nil
      @gemini_api_base = "https://generativelanguage.googleapis.com"
      @request_timeout = 120
      @max_retries = 3
      @http_proxy = nil
    end
  end
end
