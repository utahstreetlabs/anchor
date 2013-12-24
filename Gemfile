source 'https://gems.gemfury.com/pQkVXTcjthG3Ap1iMtTR'
source :rubygems

#gem 'dino', '~> 0.6.1'
gem 'dino', :path => '../dino'
gem 'unicorn'
gem 'json_patch', '~> 0.2.1'
#gem 'json_patch', path: '../json_patch'
gem 'log_weasel', path: '../log_weasel'

group :development, :test do
  gem 'rake'
  gem 'rspec'
  gem 'factory_girl'
  gem 'mocha'
  gem 'rack-test'
  gem 'foreman'
end

group :development do
  gem 'capistrano'
  gem 'capistrano-ext'
  gem 'hipchat'
  gem 'racksh'
  gem 'thor'
  if ENV['ANCHOR_DEBUG']
    gem 'ruby-debug19'
    gem 'ruby-debug-base19'
  end
end
