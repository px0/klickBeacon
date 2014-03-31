require_relative 'app' # <-- your sinatra app
require 'rspec'
require 'rack/test'

set :environment, :test

describe 'the mock api' do
	include Rack::Test::Methods

	def app
		Sinatra::Application
	end

	it "returns the imgur random link for /api/beacon/{UUID}/{Major}/{Minor}" do
		uuid = SecureRandom.uuid
		major = Random.rand(1000)
		minor = Random.rand(1000)
		get "/api/beacon/#{uuid}/#{major}/#{minor}"
		last_response.should be_ok
		last_response.body.should == "'http://imgur.com/random'"
	end
end
