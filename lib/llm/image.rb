# frozen_string_literal: true

require "base64"

module LLM
  class Image
    attr_reader :url, :data, :mime_type, :revised_prompt, :model_id

    def initialize(url: nil, data: nil, mime_type: "image/png", revised_prompt: nil, model_id: nil)
      @url = url
      @data = data
      @mime_type = mime_type
      @revised_prompt = revised_prompt
      @model_id = model_id
    end

    def to_blob
      if data
        Base64.decode64(data)
      elsif url
        require "net/http"
        require "uri"
        Net::HTTP.get(URI.parse(url))
      end
    end

    def save(path)
      File.binwrite(path, to_blob)
    end
  end
end
