require "ostruct"

class GoogleOAuth
  gem 'oauth'
  require 'oauth'
  #require 'oauth/consumer'
  CONFIG = OpenStruct.new(:google_oauth=>{
    :credentials_key=> {
      :consumer_key =>ENV["GKEY"],
      :consumer_secret =>ENV["GSECRET"],
  },
  :site=> 'https://www.google.com',
  :request_token_path=> '/accounts/OAuthGetRequestToken',
  :access_token_path=> '/accounts/OAuthGetAccessToken',
  :authorize_path=> '/accounts/OAuthAuthorizeToken',
  :apps_authorize_token_path=> '/a/%s/OAuthAuthorizeToken',
  :email_display_api_endpoint=> 'https://www.googleapis.com/userinfo/email',
  :scopes=> OpenStruct.new({
    :userinfo=> "https://www.googleapis.com/auth/userinfo#email",
    :mail=> 'https://mail.google.com/',
    :contacts=> 'https://www.google.com/m8/feeds/',
    :calendar=> 'https://www.google.com/calendar/feeds/'})

  }
  )


  ALL_SCOPES = ['calendar']

  def self.consumer(email)
   config = OpenStruct.new(CONFIG.google_oauth)
   domain = self.apps_domain(email)
   credentials = OpenStruct.new(config.credentials_key)

   OAuth::Consumer.new(
     credentials.consumer_key, credentials.consumer_secret,
     {
     :site => config.site,
     :request_token_path => config.request_token_path,
     :access_token_path => config.access_token_path,
     :authorize_path => domain ? (config.apps_authorize_token_path % domain) : config.authorize_path,
     :scheme => :query_string,
   }
   )
  end

  def self.get_services_request_token(email, callback = nil,account_types = nil)
   oauth_params = {}
   oauth_params[:oauth_callback] = callback if callback
   account_types ||= ALL_SCOPES
   scopes = account_types.map{ |t| CONFIG.google_oauth[:scopes].send(t) }
   # scopes << AppConfig.google_oauth.scopes.userinfo    # TODO: this feature seems to get 500 Internal Server Error from Google
   self.consumer(email).get_request_token(oauth_params, {:scope => scopes.join(' ')})
  end

  def self.get_authorize_url(request_token, email)
   request_token.authorize_url(:hd => apps_domain(email).to_s)
  end

  def self.get_authorize_url_and_secret(email, callback = nil, account_types = nil)
   request_token = self.get_services_request_token(email, callback, account_types)
   url = self.get_authorize_url(request_token, email)

   return url, request_token.secret
  end

  def self.get_access_token(email, request_token, request_secret, verifier)
   request_token = OAuth::RequestToken.new(GoogleOAuth.consumer(email), request_token, request_secret)

   request_token.get_access_token({}, 'oauth_verifier' => verifier)
  end

  protected

  def self.apps_domain(email)
   domain = email.split('@', 2).last
   domain = nil if domain.to_s.match(/^(gmail|googlemail)\.com$/)
   domain
  end

end

