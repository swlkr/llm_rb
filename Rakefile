# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"].exclude("test/integration_test.rb")
end

Rake::TestTask.new(:integration) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/integration_test.rb"]
end

task default: :test
