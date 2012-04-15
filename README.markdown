## Fork notes:

I updated the "twitter-oauth-sinatra" app to make it work with Google Mail and Google Apps Mail.
As a bonus, it gets the email address of the user, as we do on http://silentale.com. Quite useful if you want to use IMAP or SMTP with these tokens, with the  [gmail_xoauth](http://rubygems.org/gems/gmail_xoauth) for example :)

For your local tests, launch:

CONSUMER_KEY=mydomain.com CONSUMER_SECRET=mysecret ruby app.rb

Last version of this code can be found at https://github.com/nfo/gmail-oauth-sinatra.

Contact me at http://about.me/nfo


## Original README from https://github.com/mirven/twitter-oauth-sinatra:

directions using heroku for hosting:

create twitter app at http://twitter.com/apps
for callback url use http://<appname>.heroku.com/auth
note consumer key and consumer secret

heroku create <appname>
heroku config:add consumer_key=<consumer key from twitter> consumer_secret=<consume secret from twitter>
git push heroku master

inspired by
http://github.com/filiptepper/sinatra-oauth-1.0a-example
http://github.com/moomerman/sinitter