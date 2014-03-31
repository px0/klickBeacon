require 'sinatra'
require 'json'

get '/api/beacon/:uuid/:major/:minor' do
	content_type :json
	{:url => "http://dummyimage.com/800x600/292929/e3e3e3&text=#{params[:uuid]}-#{params[:major]}-#{params[:minor]}"}.to_json
end


