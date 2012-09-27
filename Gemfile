source :rubygems
source "http://sul-gems.stanford.edu"


gem 'dor-services', ">= 3.14.1"
gem 'rails', '3.2.6'
gem "blacklight", '~>3.5', :git => 'https://github.com/projectblacklight/blacklight.git'
gem 'blacklight-hierarchy', "~> 0.0.3"

gem 'rake'
gem 'about_page'
gem 'is_it_working-cbeer'
gem 'rack-webauth', :git => "https://github.com/sul-dlss/rack-webauth.git"
gem 'thin' # or mongrel
gem 'prawn', ">=0.12.0"
gem 'barby'
gem 'ruby-graphviz'
gem "solrizer-fedora"
gem "rsolr", :git => "https://github.com/sul-dlss/rsolr.git", :branch => "nokogiri"
gem "rsolr-client-cert", "~> 0.5.2"
gem 'confstruct', "~> 0.2.4"
gem "mysql2", "~> 0.3.0"
gem "progressbar"
gem "haml"
gem "coderay"
gem "dalli"
gem "kgio"

group :test, :development do
  gem 'unicorn'
  gem 'rspec-rails'
  gem 'capybara'
  gem "rack-test", :require => "rack/test"
end

group :development do
  gem 'pry'
  gem 'ruby-prof'
end

group :deployment do
  gem 'capistrano'
  gem 'capistrano-ext'
  gem 'rvm-capistrano'
  gem 'lyberteam-devel', '>=0.7.0', :platform => :ruby_18
  gem 'net-ssh-kerberos', :platform => :ruby_18
end

group :assets do
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
  gem 'jquery-rails'
  gem 'therubyracer', "~> 0.10.0" #, '0.11.0beta5'
  gem 'sass-rails', '~> 3.2.0'
  gem 'compass-rails', '~> 1.0.0'
  gem 'compass-susy-plugin', '~> 0.9.0'
end
