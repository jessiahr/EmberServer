require 'sinatra'
require 'redis'
ENV["REDISTOGO_URL"] = 'redis://redistogo:xxxx@xxx.redistogo.com:10975' 
ENV["APPNAME"] = 'TEST_APP'

def bootstrap_index(index_key)
  uri = URI.parse(ENV["REDISTOGO_URL"])
  redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
  index_key ||= redis.get(ENV["APPNAME"])
  return redis.get(index_key)
end

get '/*' do
  content_type 'text/html'
  bootstrap_index(params[:index_key])
end