# frozen_string_literal: true

require "test_helper"

class MimeTypesTest < Minitest::Test
  def test_detect_known
    assert_equal "image/jpeg", LLM::MimeTypes.detect("photo.jpg")
    assert_equal "image/png", LLM::MimeTypes.detect("photo.png")
    assert_equal "application/pdf", LLM::MimeTypes.detect("doc.pdf")
  end

  def test_detect_unknown
    assert_equal "application/octet-stream", LLM::MimeTypes.detect("file.xyz")
  end
end

class TokensTest < Minitest::Test
  def test_total
    tokens = LLM::Tokens.new(input: 10, output: 5)
    assert_equal 15, tokens.total
  end

  def test_defaults
    tokens = LLM::Tokens.new
    assert_equal 0, tokens.input
    assert_equal 0, tokens.output
    assert_equal 0, tokens.cached
  end
end

class ToolCallTest < Minitest::Test
  def test_parses_json_string
    tc = LLM::ToolCall.new(id: "1", name: "calc", arguments: '{"x": 1}')
    assert_equal({ "x" => 1 }, tc.arguments)
  end

  def test_accepts_hash
    tc = LLM::ToolCall.new(id: "1", name: "calc", arguments: { "x" => 1 })
    assert_equal({ "x" => 1 }, tc.arguments)
  end
end

class ContentTest < Minitest::Test
  def test_simple
    c = LLM::Content.new(text: "hello")
    assert c.simple?
    assert_equal "hello", c.to_s
  end

  def test_with_attachments
    att = LLM::Attachment.new(source: "photo.jpg")
    c = LLM::Content.new(text: "look", attachments: [att])
    refute c.simple?
  end
end

class MessageTest < Minitest::Test
  def test_wraps_string_content
    msg = LLM::Message.new(role: :user, content: "hello")
    assert_instance_of LLM::Content, msg.content
    assert_equal "hello", msg.content.to_s
  end

  def test_role_predicates
    assert LLM::Message.new(role: :assistant).assistant?
    assert LLM::Message.new(role: :user).user?
    assert LLM::Message.new(role: :tool).tool?
    assert LLM::Message.new(role: :system).system?
  end

  def test_string_role
    msg = LLM::Message.new(role: "user")
    assert_equal :user, msg.role
    assert msg.user?
  end
end

class ChunkTest < Minitest::Test
  def test_struct
    chunk = LLM::Chunk.new(content: "hi", model_id: "gpt-4o")
    assert_equal "hi", chunk.content
    assert_equal "gpt-4o", chunk.model_id
  end
end

class SchemaTest < Minitest::Test
  def test_attrs
    s = LLM::Schema.new(name: "Person", schema: { type: "object" })
    assert_equal "Person", s.name
    assert_equal({ type: "object" }, s.schema)
  end
end

class ImageTest < Minitest::Test
  def test_save
    img = LLM::Image.new(data: Base64.strict_encode64("PNG_DATA"))
    path = File.join(Dir.tmpdir, "test_llm_img.png")
    img.save(path)
    assert_equal "PNG_DATA", File.binread(path)
  ensure
    File.delete(path) if path && File.exist?(path)
  end
end
