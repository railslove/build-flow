# Build Flow

This application will takes webhook callbacks from various sources
and trigger a site build and subsequent deployment.

Rightnow the Middleman application must be already configured to
be deployable with `middleman-s3_sync`.

## Configuration

* BUILD_INTERVAL, how often shall we check for an deploy to happen (defaults to 500sec)
* GH_REPOSITORY, the repo to deploy, should include the user/organization
* GH_TOKEN, an OAuth token to clone the application
* AWS_ACCESS_KEY, the name suggests what it is :)
* AWS_SECRET_KEY, you get the idea

If you want to secure the endpoint, please go with these:

* AUTH_USER
* AUTH_PASSWORD

When _both_ are set, we'll present a beautiful Basic Auth dialog.

## Deploy

Check out and deploy it to whatever platform you like. Maybe Heroku
is worth a try.

Take the URL that will point to the just deployed application and put
it everywhere changes should trigger a new build. Keep in mind that you
also pass any basic auth credentials if configured before.

So... you're done! Concentrate on something more important :)