This project is now for a calendar hack. When a user signs up they pick
a google calendar to be viewed publicly. They pick a user name which
will be part of the user. When another person goes to that url they will
see the user's free and busy time. They can then create apt with the
user. 

Using rvm and bundler. Gemset name is cfur because it was another
project I forked to make this. 

example here:

https://radiant-river-1114.herokuapp.com/becker

You now need to set GKEY and GSECRET. Why? Because I didnt read the readme when I started. 


Original Project Notes:
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
