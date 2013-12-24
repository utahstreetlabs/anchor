require 'rubygems'
require 'bundler'

Bundler.setup :default, :test
ENV['RACK_ENV'] = 'test'

require 'rspec'
require 'factory_girl'
require 'dino/test/response'

require 'dino'
require 'dino/kaminari'

Dir[File.join("./spec/support/**/*.rb")].each {|f| require f}

Dir.mkdir('log') unless File.exists?('log')

Dino.logger = Mongoid.logger = Logger.new('log/test.log')
Mongoid.load!(File.join('config', 'mongoid.yml'))

Kaminari.configure do |config|
  config.default_per_page = 100
end

RSpec.configure do |config|
  config.mock_with :mocha
  config.after(:each) do
    Mongoid.master.collections.select {|c| c.name !~ /system/ }.each(&:drop)
  end
end
