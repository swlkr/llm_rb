# frozen_string_literal: true

module LLM
  class Tool
    class << self
      def description(text = nil)
        if text
          @description = text
        else
          @description
        end
      end

      def param(name, type:, desc: nil, required: true)
        params << { name: name, type: type, desc: desc, required: required }
      end

      def params
        @params ||= []
      end

      def parameters
        params
      end

      def tool_name
        name.split("::").last
            .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
            .gsub(/([a-z\d])([A-Z])/, '\1_\2')
            .downcase
      end

      def to_json_schema
        properties = {}
        required = []

        params.each do |p|
          properties[p[:name].to_s] = {
            type: p[:type].to_s
          }
          properties[p[:name].to_s][:description] = p[:desc] if p[:desc]
          required << p[:name].to_s if p[:required]
        end

        schema = {
          type: "object",
          properties: properties
        }
        schema[:required] = required unless required.empty?
        schema
      end
    end

    def call(**args)
      execute(**args)
    rescue => e
      "Error: #{e.message}"
    end

    def execute(**args)
      raise NotImplementedError, "Subclasses must implement #execute"
    end
  end
end
