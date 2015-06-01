A Simple example of setting up Ember Deploy to use AWS S3 and Redis to distribute your app. 
(there is way more documentation at https://github.com/ember-cli/ember-cli-deploy but this is what has worked for me) 

- My hope is that this saves someone some time and energy trying to just get something publicly visible .

Setup a Redis instance
----
Go to www.redistogo.com and setup a free instance.
Once the instance is online find its URL:
`redis://redistogo:xxxxxxxxxxxxxxxxxxxxx@goofybits.redistogo.com:10975`
This will be what you use as your REDISTOGO_URL in the next step.

Note: the "xxxxxxxxxxxxxxxxxxxxx" portion of the url will be your password and the part after the `@` is your host(goofybits)


Create a bucket in AWS S3
------
- first find your aws console api keys (click your name in the nav then security)
- create a new bucket
- https://console.aws.amazon.com/s3/



Modify your Brocfile
----
Make changes to the way your assets are packaged when doing a production build (see ember-cli-deploy for more info)
Here is what works for me:
`
var isProductionLikeBuild = ['production', 'staging'].indexOf(env) > -1;
var app = new EmberApp({
fingerprint: {
    enabled: isProductionLikeBuild,
    prepend: 'https://YOUR_BUCKET_NAME.s3.amazonaws.com/'
  },
  sourcemaps: {
    enabled: !isProductionLikeBuild,
  },
  minifyCSS: { enabled: isProductionLikeBuild },
  minifyJS: { enabled: isProductionLikeBuild },

  tests: process.env.EMBER_CLI_TEST_COMMAND || !isProductionLikeBuild,
  hinting: process.env.EMBER_CLI_TEST_COMMAND || !isProductionLikeBuild,

  vendorFiles: {
    'handlebars.js': {
      staging:  'bower_components/handlebars/handlebars.runtime.js'
    },
    'ember.js': {
      staging:  'bower_components/ember/ember.prod.js'
    }
  }
});
`
Add the ember deploy addon to your ember cli project\
----
Follow the instructions @ https://www.npmjs.com/package/ember-cli-deploy

The short version:
- `npm install ember-cli-deploy --save-dev`
- create a deploy.js file in the config folder of your ember-cli app
```
module.exports = {
  production: {
    buildEnv: 'development', // Override the environment passed to the ember asset build. Defaults to 'production'
    store: {
      type: 'redis', // the default store is 'redis'
      host: 'goofybits.redistogo.com',
      password:"xxxxxxxxxxxxxxxxxxxxx",
      port: 10975
    },
    assets: {
      type: 's3', // default asset-adapter is 's3'
      gzip: true, // if undefined or set to true, files are gziped
      gzipExtensions: ['js', 'css', 'svg'], // if undefined, js, css & svg files are gziped
      accessKeyId: 'YOUR AWS KEY',
      secretAccessKey: 'YOUR AWS SECRET',
      bucket: 'letterapp'
    }
  },

};
``` 



Setup a simple webserver
---
This repository is a boilerplate Sinatra server that only needs two variables to get up and running:
    ENV["REDISTOGO_URL"] = 'redis://redistogo:xxxxxxxxxxxxxxxxxxxxx@goofybits.redistogo.com:10975' 
    ENV["APPNAME"] = 'TEST_APP'

Run local 
----
- make sure you have ruby installed
- open the emberserver in terminal 
- run `bundle install`
- run `rackup`

You should have a webserver running on localhost:9292! There will not be any content yet because we have not run a deploy through ember-cli-deploy

Deploy a version
---
- commit the changes to your ember-cli app
- run `ember deploy -prod`  (we are using the production environment but you can also use staging if you set it up in your deploy.js file.)
- you should see:
`
Built project successfully. Stored in "dist/".
Uploading assets...
Uploading: gutenberg.css
Uploading: gutenberg.js
Uploading: gutenberg.map
Uploading: index.html
Uploading: index.html
Assets upload successful. Done uploading.

Trying to upload `dist/index.html`...


Upload successful!

Uploaded revision: YOURAPP:90c5190
`

note that last piece `YOURAPP:90c5190` because you will use the commit hash to select which version you want to be active.

to activate the latest version run `ember deploy:activate --revision YOURAPP:90c5190 --prod`

Open localhost:9292 and you should now see your app!


Publish to Heroku
---

in the EmberServer folder run `heroku create` to create a new instance and then run `git push origin master` to deploy.
You will need to either hard code the environment variables (`ENV["REDISTOGO_URL"]`)or set them via the heroku config page.

navigate to your app's url and you should see it boot up 


Troubleshooting 
---
If the page does not load check that the Sinatra app deployed correctly.
If the page does not load check that you have run a ember-cli-deploy AND activated it (look at the docs and check which one is selected as active)
If the ember-cli-deploy fails it usually will be because you forgot to commit the changes (the commit hash is the key used to identify versions in redis)
If the page loads but the assets fail to load check your Brocfile to see how your assets are being handled and also check your environment.js / contentSecurityPolicy to make sure the url where the assets are being loaded from (`xxxx.s3-some-region.com `) is whitelisted. 






