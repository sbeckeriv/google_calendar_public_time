require "rubygems"
require "sinatra"
require 'json'
require "oauth"
require "oauth/consumer"
require 'haml'
require File.join(Dir.pwd,"google_o_auth.rb")
require "pp"
require File.join(Dir.pwd,"cfur.rb")
require 'data_mapper'
enable :sessions
#TODO:
#  Cache google calendar data so we dont make so many calls.
#  Clean up code
#  Add calendar options and user settings
#  Clean up assets
#    Bootstraped is mixed with old bootstrap for date/time selectors
#    Removed unused bootstrap elements
#  UI
#  Clean up the gemfile. The postgres stuff was confusing. It works now.
#  
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/cfur.db")
class Users
  include DataMapper::Resource
  property :id,         Serial
  property :email, String
  property :token, String
  property :secret, String
  property :request_token, String
  property :calendar_names, Text
  property :public_calendar, Text
  property :url_name, Text
  property :locations, Text
  property :timezone, String
end
Users.auto_migrate! unless Users.storage_exists?

before do
  session[:oauth] ||= {}  
  consumer_key =ENV["GKEY"]
  consumer_secret =ENV["GSECRET"]

  @consumer =nil
  @consumer= GoogleOAuth.consumer( session[:cfur][:email]) if session && session[:cfur] && session[:cfur][:email]
  @user = Users.first({:email=>session[:cfur][:email]})  if session && session[:cfur] && session[:cfur][:email]

  if !session[:oauth][:request_token].nil? && !session[:oauth][:request_token_secret].nil?
    @request_token = OAuth::RequestToken.new(@consumer, session[:oauth][:request_token], session[:oauth][:request_token_secret])
  end

  if !session[:oauth][:access_token].nil? && !session[:oauth][:access_token_secret].nil?
    @access_token = OAuth::AccessToken.new(@consumer, session[:oauth][:access_token], session[:oauth][:access_token_secret])
  end

end
BAD_WORDS = %W{delete create update auth request logout }

get "/delete" do
  if(@access_token && session && @user)
    @user.destroy
  end  
  redirect "/"
end

post "/create" do
  content_type :json
  begin
    account_name = params[:account]
    user = Users.first({:public_calendar=>account_name})
    consumer_key =ENV["GKEY"]
    consumer_secret =ENV["GSECRET"]
    location = params[:location]
    if location =~ /other/i
      location =params[:location_other].empty? ? "Other" : params[:location_other]
    end
    event = {
      'summary' => 'Auto Appointment for '+params[:name]+" about "+params[:summary],
      'location' => location,
      'guestsCanSeeOtherGuests' => false,
      'visibility'=>"private",
      'status'=>'tentative',
      'guestsCanModify'=>false,
      "guestsCanInviteOthers"=>false,
      'organizer'=>{
      'email' => params[:email],
      "displayName" => params[:name]
    },
      'start' => {
      'dateTime' => "#{params["start-date"]}T#{params["start-time"]}:00.000-#{"%02d" %params[:offset]}:00"
    },
      'end' => {
      'dateTime' => "#{params["end-date"]}T#{params["end-time"]}:00.000-#{"%02d" %params[:offset]}:00"
    },
      'attendees' => [{
      'email' => params[:email],
      "displayName" => params[:name]
    }
    ],
      'description'=>params[:descripton],#note misspelled
    }
    consumer= GoogleOAuth.consumer(user.email.strip)  
    access_token = OAuth::AccessToken.new(consumer, user.token, user.secret)
    account =  access_token.post("https://www.googleapis.com/calendar/v3/calendars/#{user.public_calendar}/events",JSON.dump(event),{'Content-Type' => 'application/json'})
    { :success => 'good'}.to_json
  rescue Exception=>e
    { :bad=> e.message}.to_json

  end
end

get "/" do
  if @access_token && session && user=Users.first({:secret=>session[:oauth][:access_token_secret]})
    @cal =CFur.get_cal_list(@access_token)
    @user = user
    if @user && @user.public_calendar && !@user.public_calendar.empty?
      consumer= GoogleOAuth.consumer(user.email.strip)  
      access_token = OAuth::AccessToken.new(consumer, user.token, user.secret)
      begin  
        ac=  access_token.get("https://www.googleapis.com/calendar/v3/calendars/#{@user.public_calendar}/acl",{'Content-Type' => 'application/json'}).body
        pp ac
        @acl = JSON.parse ac
      rescue Exception=>e
        pp e
      end

    end
    @flash = session.delete(:flash)
    haml :index
  else
    session.clear
    haml :sign
  end
end

post "/update" do
  if(@access_token && session && user=Users.first({:secret=>session[:oauth][:access_token_secret]}))
    named_user = Users.first({:url_name=>params[:name]})
    if( params[:acl_update])
      consumer= GoogleOAuth.consumer(user.email.strip)  
      access_token = OAuth::AccessToken.new(consumer, user.token, user.secret)
      begin
        j={
          "scope"=> {
          "type"=> "default",
          "value"=> "__public_principal__@public.calendar.google.com"
        },
          "role"=> "freeBusyReader"
        }
        acl = access_token.post("https://www.googleapis.com/calendar/v3/calendars/#{params[:calendar]}/acl",JSON.generate(j),{'Content-Type'=>'application/json'})
      rescue Exception=>e
        session[:flash]="There was an error talking to google. Please try again"
        puts e
        puts e.message
      end


    elsif(named_user && named_user.id!=@user.id) || params[:name].empty? 
      session[:flash]="Settings not updated username taken."
    elsif params[:name].match(/\W/)
      session[:flash]="Name can only be letters, numbers and underscore"
    elsif BAD_WORDS.include?(params[:name])
      session[:flash]="Thats my word. Pick a new one! "
    else
      consumer= GoogleOAuth.consumer(user.email.strip)  
      access_token = OAuth::AccessToken.new(consumer, user.token, user.secret)
        cal =  access_token.get("https://www.googleapis.com/calendar/v3/calendars/#{params[:calendar]}",{'Content-Type' => 'application/json'})
        cal = JSON.parse cal.body
        user.url_name = params[:name]
        user.public_calendar = params[:calendar]
        user.locations = params[:locations]
        user.timezone = cal["timeZone"]
        user.save
      session[:flash]="Settings updated"
    end
  else
    session[:flash]="Settings not updated"
  end
  redirect "/"
end


get "/request" do
  email = params[:email]
  session[:cfur]={}
  #write to storage
  session[:cfur][:email]=email
  url,token = GoogleOAuth.get_authorize_url_and_secret(email,"#{request.scheme}://#{request.host}:#{request.port}/auth?email=#{email}")
  user=Users.first_or_create({:email=>email},{:email=>email,:request_token=>token})
  user.request_token=token
  user.email=email
  user.save
  redirect url
end

get "/auth" do
  email = params[:email]
  raise "error" if email!=session[:cfur][:email] # also add in some hashing 
  consumer_key =ENV["GKEY"]
  consumer_secret =ENV["GSECRET"]
  user=Users.first({:email=>email})
  r = GoogleOAuth.get_services_request_token(email,"#{request.scheme}://#{request.host}:#{request.port}/auth?email=#{email}")
  @access_token = GoogleOAuth.get_access_token(email,params[:oauth_token],user.request_token,params[:oauth_verifier])
  user.token=@access_token.token
  user.secret=@access_token.secret
  list =  CFur.get_cal_list(@access_token)
  if(list)
    if list["data"] && list["data"]["items"] && (!user.calendar_names || user.calendar_names.empty?)
      user.calendar_names=list["data"]["items"].map{|j| j["id"].split("/").last}.join(",")
    end
  end
  user.save
  session[:oauth][:access_token] = @access_token.token
  session[:oauth][:access_token_secret] = @access_token.secret
  redirect "/"
end

get "/logout" do
  session[:oauth] = {}
  redirect "/"
end

get %r{/(\w+)}i do |name|
  named_user = Users.first({:url_name=>name})
  if named_user
    @user = named_user
    haml :calendar
  else
    session[:flash]= "Did not find a user under the name #{params[:name]}"
    redirect "/"
  end
end
