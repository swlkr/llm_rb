# frozen_string_literal: true

module LLM
  module MimeTypes
    TYPES = {
      ".jpg" => "image/jpeg",
      ".jpeg" => "image/jpeg",
      ".png" => "image/png",
      ".gif" => "image/gif",
      ".webp" => "image/webp",
      ".svg" => "image/svg+xml",
      ".pdf" => "application/pdf",
      ".mp3" => "audio/mpeg",
      ".wav" => "audio/wav",
      ".mp4" => "video/mp4",
      ".webm" => "video/webm",
      ".json" => "application/json",
      ".txt" => "text/plain",
      ".html" => "text/html",
      ".css" => "text/css",
      ".js" => "application/javascript",
      ".xml" => "application/xml",
      ".csv" => "text/csv"
    }.freeze

    def self.detect(path)
      ext = File.extname(path.to_s).downcase
      TYPES[ext] || "application/octet-stream"
    end
  end
end
