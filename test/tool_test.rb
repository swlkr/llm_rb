# frozen_string_literal: true

require "test_helper"

class TestCalculator < LLM::Tool
  description "Performs math calculations"
  param :expression, type: :string, desc: "Math expression to evaluate"

  def execute(expression:)
    eval(expression).to_s
  end
end

class MultiParamTool < LLM::Tool
  description "Has multiple params"
  param :name, type: :string, desc: "A name"
  param :age, type: :integer, desc: "An age", required: false

  def execute(name:, age: nil)
    "#{name} is #{age}"
  end
end

class ToolTest < Minitest::Test
  def test_tool_name
    assert_equal "test_calculator", TestCalculator.tool_name
  end

  def test_description
    assert_equal "Performs math calculations", TestCalculator.description
  end

  def test_parameters
    params = TestCalculator.parameters
    assert_equal 1, params.size
    assert_equal :expression, params[0][:name]
    assert_equal :string, params[0][:type]
  end

  def test_to_json_schema
    schema = TestCalculator.to_json_schema
    assert_equal "object", schema[:type]
    assert_includes schema[:properties], "expression"
    assert_includes schema[:required], "expression"
  end

  def test_optional_param
    schema = MultiParamTool.to_json_schema
    assert_includes schema[:required], "name"
    refute_includes schema[:required], "age"
  end

  def test_call
    tool = TestCalculator.new
    assert_equal "4", tool.call(expression: "2 + 2")
  end

  def test_call_rescues_errors
    tool = TestCalculator.new
    result = tool.call(expression: "invalid_method_xyz")
    assert_match(/Error:/, result)
  end
end
