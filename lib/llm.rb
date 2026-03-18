# frozen_string_literal: true

require "json"
require "uri"
require "base64"
require "logger"

require_relative "llm/version"
require_relative "llm/error"
require_relative "llm/configuration"
require_relative "llm/mime_types"
require_relative "llm/tokens"
require_relative "llm/tool_call"
require_relative "llm/content"
require_relative "llm/attachment"
require_relative "llm/message"
require_relative "llm/chunk"
require_relative "llm/tool"
require_relative "llm/schema"
require_relative "llm/image"
require_relative "llm/stream_accumulator"
require_relative "llm/provider"
require_relative "llm/chat"
require_relative "llm/providers/openai"
require_relative "llm/providers/anthropic"
require_relative "llm/providers/gemini"

module LLM
  class << self
    def configure
      yield(config)
    end

    def config
      @config ||= Configuration.new
    end

    def chat(model:, provider: nil, **opts)
      prov = resolve_provider(model, provider)
      Chat.new(provider: prov, model: model, **opts)
    end

    def paint(prompt, model: "dall-e-3", provider: nil, **opts)
      prov = resolve_provider(model, provider)
      prov.paint(prompt, model: model, **opts)
    end

    def logger
      @logger ||= Logger.new($stdout, level: Logger::WARN)
    end

    def logger=(log)
      @logger = log
    end

    def reset!
      @config = Configuration.new
      @providers = {}
    end

    private

    def resolve_provider(model, explicit_provider)
      provider_key = explicit_provider || infer_provider(model)
      providers[provider_key] ||= build_provider(provider_key)
    end

    def providers
      @providers ||= {}
    end

    def infer_provider(model)
      case model.to_s
      when /\Aclaude/i then :anthropic
      when /\Agemini/i then :gemini
      else :openai
      end
    end

    def build_provider(key)
      case key.to_sym
      when :openai then Providers::OpenAI.new(config)
      when :anthropic then Providers::Anthropic.new(config)
      when :gemini then Providers::Gemini.new(config)
      else raise ConfigurationError, "Unknown provider: #{key}"
      end
    end
  end
end
