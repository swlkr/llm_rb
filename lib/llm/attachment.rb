# frozen_string_literal: true

require "base64"

module LLM
  class Attachment
    attr_reader :source, :mime_type, :filename

    def initialize(source:, mime_type: nil, filename: nil)
      @source = source
      @mime_type = mime_type || detect_mime_type
      @filename = filename || detect_filename
    end

    def base64_data
      if url?
        require "net/http"
        require "uri"
        uri = URI.parse(source)
        response = Net::HTTP.get(uri)
        Base64.strict_encode64(response)
      else
        Base64.strict_encode64(File.binread(source))
      end
    end

    def image?
      mime_type&.start_with?("image/")
    end

    def pdf?
      mime_type == "application/pdf"
    end

    def url?
      source.to_s.match?(%r{\Ahttps?://})
    end

    private

    def detect_mime_type
      MimeTypes.detect(source)
    end

    def detect_filename
      url? ? File.basename(URI.parse(source).path) : File.basename(source.to_s)
    end
  end
end
