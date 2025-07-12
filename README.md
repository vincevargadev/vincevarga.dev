# `vincevarga.dev`

This is my main website containing my blog and portfolio.

The website is built with [Hugo](https://gohugo.io/). The used theme is a [forked, customized version](https://github.com/vincevargadev/gohugo-theme-vedi) of the [Hugo Ed theme](https://github.com/sergeyklay/gohugo-theme-ed/).

## Development

1. Make sure Go is installed locally.
    * Install with `brew install go` on Mac.
    * Verify installation with `go version` 
2. Make sure Hugo is installed locally.
    * Install with `brew install hugo` on Mac.
    * Verify installation with `hugo version`
3. `hugo mod get`
4. `hugo serve`

## Release

### Release with a script

The [`release.sh`](./release.sh) goes through all the steps needed for releasing the blog to [`vincevarga.dev`](https://vincevarga.dev).

```
# Make the release script executable (optional)
chmod +x release.sh
# Run the release script, it will build the blog and copy over content to the server.
./release.sh
# Verify changes (optional)
open https://vincevarga.dev"
```

Key steps:
* SSH configuration and server details
* Build `public` with `hugo build`
* Backup previous content, so that restoring previous version is possible (manually)
* Copy `Caddyfile` and `public` folder to the server
* Restart Caddy
* Clean up old backups on the server

I went with a very simple approach so that it runs on a server I control (I can add other apps later), easy to understand, and easy to debug.

## Next
