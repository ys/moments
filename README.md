# Instant portfolio over dropbox

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

## Usage

- Go to `[DROPBOX_FOLDER]/Apps/[THE_APP_CREATED_IN_DROPBOX]`
- Create folder for new moments you want to share.
- Add a cover picture by naming a picture `_cover.jpg`
- Add pictures to the folder.
- Flush memcached at `https://addons-sso.heroku.com/apps/[HEROKU_APP]/addons/memcachier`
- Enjoy!

## See it in action

[![](http://cl.ly/image/013226172504/Screen%20Shot%202014-09-11%20at%209.58.49%20AM.png)](https://moments.yannick.io)
 

[1]: https://www.dropbox.com/developers/apps/create