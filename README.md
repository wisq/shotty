# Shotty

Shotty is a simple web server that serves the Nth most recent file(s) from the configured directories on demand.

It comes with a lightweight bash script (using `curl` and `unzip`) that downloads files and automatically supplies them as arguments to the given command (e.g. `open` on Mac).

Shotty is designed for screenshots (hence the name), but it technically doesn't care about the contents of the files, and can work with any file type.

## Installation

On the server:

1. Install [Elixir](https://elixir-lang.org/) v1.14 or higher.
2. Run `mix deps.get` to fetch dependencies.
3. Configure your server by editing `config/prod.exs` (which contains my own personal configuration as an example).
    * See [Configuring Shotty](CONFIGURATION.md) for details, including the various indexers available.
    * Note the port; you'll need that later for `SHOTTY_URL`, below.
4. Run `MIX_ENV=prod mix run --no-halt` to launch the server.
    * On Windows, see `shotty.bat` for an example.

On the client:

1. Copy `bin/shotty` to somewhere in your `$PATH`.
    * *(optional)* Also copy `bin/quicklook` to your `$PATH` if you want to use the `-q` option.
2. Edit your shell profile, and/or set these variables manually:
    * `SHOTTY_URL` – URL to the shotty server, e.g. `http://myserver.local:4000/`
    * `SHOTTY_PATH` — Directory to store downloaded files in

And you're all set!

## Usage

Basic usage:

 * `shotty mypath` — fetch the most recent file from the `mypath` path, and open it with `open`

With the optional `count` argument, you can choose which file(s) to retrieve:

 * `shotty mypath 1` — fetch the most recent file (same as not specifying `count` at all)
 * `shotty mypath 5` — fetch the 5th most recent file
 * `shotty mypath 7..9` — fetch the 7th through 9th most recent files (in a single request)

With additional arguments, you can choose how to open the downloaded file(s):

 * *(no arguments)* — open with the default app based on file type (typically `Preview` for images)
 * `-a Firefox` or `-aFirefox` — open the file with Firefox (e.g. `/Applications/Firefox.app`)
 * `-q` — open the file using "Quick Look" in Finder
   * This is useful because Quick Look can do certain things Preview can't, such as using an iPad (and optional Apple Pencil) to mark up the image.
 * `-p` — open the file using Adobe Photoshop
   * If you have multiple Photoshop versions installed, the script will try to pick the most recent one.

It should be fairly easy to customise the script to add your own common tools.  (You'll definitely need to do this if your client isn't a Mac.)

## Security

The Shotty server is very minimal, and should not pose much of a vulnerability risk.  It will only serve files from the specified directories, and not from any subdirectories (except for the `steam` indexer).  Barring any exploits in Elixir's libraries, the only risks should be if the server is misconfigured to serve sensitive files, or if symbolic links to sensitive files are created in the screenshot directories.  (Of course, these are also standard concerns with any file-serving software in general.)

The server also does not ever need to write to disk (except during compilation).  As such, as long as you run `mix compile` beforehand, the `mix run` stage can be performed as an unprivileged user, e.g. `nobody`.

The client script will unzip any response with a `content-type: application/zip` header (making it potentially vulnerable to malicious zip files) and then open any files found inside (a *very obvious* vulnerability!).  Make sure your `SHOTTY_URL` variable is pointing at your own server, and be sure to use fully-validated HTTPS if using Shotty over a public network (especially the internet).

## Legal stuff

Copyright © 2023, Adrian Irving-Beer.

Shotty is released under the [MIT license](LICENSE) and is provided with **no warranty**.  I'm not responsible if your Shotty server gives hackers access to your system, or if you run arbitrary code by downloading untrusted files.

Steam and Adobe Photoshop are trademarks of their relevant companies.
