require 'sinatra'

get '/api/beacon/:uuid/:major/:minor' do
	"'http://dummyimage.com/800x600/292929/e3e3e3&text=#{params[:uuid]}-#{params[:major]}-#{params[:minor]}'"
end


