require 'rubygems'
require 'bundler'

Bundler.setup

require 'mocha'
require 'rspec'
require 'ladon'
require 'anchor/resource/base'

Ladon.hydra = Typhoeus::Hydra.new
Ladon.logger = Logger.new('/dev/null')

Anchor::Resource::Base.base_url = 'http://localhost:4011'

RSpec.configure do |config|
  config.mock_with :mocha
end
