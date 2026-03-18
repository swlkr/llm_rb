# frozen_string_literal: true

module LLM
  class Error < StandardError
    attr_reader :status, :body

    def initialize(message = nil, status: nil, body: nil)
      @status = status
      @body = body
      super(message)
    end
  end

  class ConfigurationError < Error; end
  class BadRequestError < Error; end
  class UnauthorizedError < Error; end
  class RateLimitError < Error; end
  class ServerError < Error; end
  class ServiceUnavailableError < Error; end
  class ContextLengthExceededError < Error; end

  ERROR_MAP = {
    400 => BadRequestError,
    401 => UnauthorizedError,
    403 => UnauthorizedError,
    429 => RateLimitError,
    500 => ServerError,
    502 => ServiceUnavailableError,
    503 => ServiceUnavailableError,
    529 => ServiceUnavailableError
  }.freeze
end
