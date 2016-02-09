$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'webmock/rspec'
WebMock.disable_net_connect!

require 'coveralls'
Coveralls.wear!

require 'homebrew/github/bottles'
