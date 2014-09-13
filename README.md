# Share your moments, over dropbox.
**Heroku + Dropbox + your pictures = :heart:**

## Requirements

- A dropbox account
- Nice pictures to show

## Setup

### Dropbox

- Create a [new dropbox app][1]
![](http://cl.ly/image/3y1x0x1T1S3R/Screen%20Shot%202014-09-11%20at%209.12.31%20AM.png)
- Get the token
![](http://cl.ly/image/01461w1z1K37/Artboard.png)

### Heroku
[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

*Use the token generated in the dropbox part in setup*

### Dropbox Webhook

This will clean the cache when you add new pictures or moments to your dropbox folder.  
*You can do it manually via the settings of your app on heroku also but this is the* **recommended way**.

- Get `FLUSH_TOKEN` via `$ heroku config`
- Fill the `Webhook URIs` field with `http://[YOUR_APP].herokuapp.com/cache/flush?t=[FLUSH_TOKEN]`
![](http://cl.ly/image/3i1X0L1B0U3e/Screen%20Shot%202014-09-13%20at%2010.22.55%20PM.png)

## Usage

- Go to `[DROPBOX_FOLDER]/Apps/[THE_APP_CREATED_IN_DROPBOX]`
- Create folder for new moments you want to share.
- Add a cover picture by naming a picture `_cover` and any extension you want.
- Want password protection? Add a `password.txt` file. Content is the password.
- Add pictures to the folder.
- Enjoy!

## See it in action

[![](http://cl.ly/image/013226172504/Screen%20Shot%202014-09-11%20at%209.58.49%20AM.png)](https://moments.yannick.io)


[1]: https://www.dropbox.com/developers/apps/create
