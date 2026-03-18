# frozen_string_literal: true

module LLM
  class Chat
    attr_reader :messages, :model, :provider

    MAX_TOOL_ITERATIONS = 10

    def initialize(provider:, model:, temperature: nil, tools: nil, schema: nil, instructions: nil)
      @provider = provider
      @model = model
      @temperature = temperature
      @tools = build_tools_hash(tools)
      @schema = schema
      @instructions = instructions
      @messages = []
    end

    def ask(message, &block)
      add_system_message if @messages.empty? && @instructions
      @messages << Message.new(role: :user, content: message)
      complete(&block)
    end

    def with_model(new_model)
      if infer_provider(new_model) != infer_provider(@model)
        @provider = LLM.send(:resolve_provider, new_model, nil)
      end
      @model = new_model
      self
    end

    def with_tools(*tool_classes)
      @tools = build_tools_hash(tool_classes.flatten)
      self
    end

    def with_schema(name:, schema:)
      @schema = Schema.new(name: name, schema: schema)
      self
    end

    def with_instructions(text)
      @instructions = text
      @messages.reject! { |m| m.system? }
      @messages.unshift(Message.new(role: :system, content: text)) unless text.nil?
      self
    end

    def with_temperature(temp)
      @temperature = temp
      self
    end

    def last_message
      @messages.select(&:assistant?).last
    end

    private

    def add_system_message
      @messages.unshift(Message.new(role: :system, content: @instructions))
    end

    def complete(&block)
      response = @provider.complete(
        @messages,
        model: @model,
        tools: @tools.empty? ? nil : @tools,
        schema: @schema,
        temperature: @temperature,
        stream: block_given?,
        &block
      )

      @messages << response
      handle_tool_calls(response, &block)
    end

    def handle_tool_calls(response, iteration: 0, &block)
      return response unless response.tool_calls && !response.tool_calls.empty?
      return response if iteration >= MAX_TOOL_ITERATIONS

      response.tool_calls.each do |tc|
        tool_class = @tools[tc.name]
        result = if tool_class
                   tool_instance = tool_class.new
                   tool_instance.call(**tc.arguments.transform_keys(&:to_sym))
                 else
                   "Error: Unknown tool '#{tc.name}'"
                 end

        @messages << Message.new(
          role: :tool,
          content: result.to_s,
          tool_call_id: tc.id
        )
      end

      next_response = @provider.complete(
        @messages,
        model: @model,
        tools: @tools.empty? ? nil : @tools,
        schema: @schema,
        temperature: @temperature,
        stream: block_given?,
        &block
      )

      @messages << next_response
      handle_tool_calls(next_response, iteration: iteration + 1, &block)
    end

    def build_tools_hash(tool_classes)
      return {} if tool_classes.nil? || tool_classes.empty?
      tool_classes.each_with_object({}) { |tc, h| h[tc.tool_name] = tc }
    end

    def infer_provider(model)
      case model.to_s
      when /\Aclaude/i then :anthropic
      when /\Agemini/i then :gemini
      else :openai
      end
    end
  end
end
