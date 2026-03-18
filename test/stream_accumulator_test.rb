# frozen_string_literal: true

require "test_helper"

class StreamAccumulatorTest < Minitest::Test
  def test_accumulates_content
    acc = LLM::StreamAccumulator.new
    acc.add(content: "Hello")
    acc.add(content: " world")
    msg = acc.to_message
    assert_equal "Hello world", msg.content.to_s
  end

  def test_accumulates_tool_calls
    acc = LLM::StreamAccumulator.new
    acc.add(tool_call_id: "call_1", tool_call_name: "calc", tool_call_arguments: '{"ex')
    acc.add(tool_call_id: "call_1", tool_call_arguments: 'pression":"2+2"}')
    msg = acc.to_message
    assert_equal 1, msg.tool_calls.size
    assert_equal "calc", msg.tool_calls[0].name
    assert_equal({ "expression" => "2+2" }, msg.tool_calls[0].arguments)
  end

  def test_accumulates_tokens
    acc = LLM::StreamAccumulator.new
    acc.add(input_tokens: 10)
    acc.add(output_tokens: 5)
    msg = acc.to_message
    assert_equal 10, msg.tokens.input
    assert_equal 5, msg.tokens.output
  end

  def test_empty_accumulator
    acc = LLM::StreamAccumulator.new
    msg = acc.to_message
    assert msg.assistant?
    assert_equal "", msg.content.to_s
    assert_empty msg.tool_calls
  end
end
