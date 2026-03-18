# frozen_string_literal: true

require "test_helper"

class ErrorTest < Minitest::Test
  def test_error_with_status_and_body
    err = LLM::Error.new("Something went wrong", status: 500, body: { "error" => "bad" })
    assert_equal "Something went wrong", err.message
    assert_equal 500, err.status
    assert_equal({ "error" => "bad" }, err.body)
  end

  def test_error_map
    assert_equal LLM::BadRequestError, LLM::ERROR_MAP[400]
    assert_equal LLM::UnauthorizedError, LLM::ERROR_MAP[401]
    assert_equal LLM::RateLimitError, LLM::ERROR_MAP[429]
    assert_equal LLM::ServerError, LLM::ERROR_MAP[500]
    assert_equal LLM::ServiceUnavailableError, LLM::ERROR_MAP[503]
  end

end
