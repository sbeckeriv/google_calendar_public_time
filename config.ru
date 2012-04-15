if( !ENV["GKEY"] || !ENV["GSECRET"] || ENV["GSECRET"].empty? || ENV["GKEY"].empty?)
  $stderr.puts("NEED TO SET GKEY AND GSECRET")
  exit
end
require File.join(Dir.pwd,'app.rb')
run Sinatra::Application
