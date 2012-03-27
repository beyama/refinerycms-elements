require 'refinerycms-testing'

RSpec.configure do |config|
  config.extend Elements::Testing::CompilerMacros
  config.include Elements::Testing::CompilerMacros
end
