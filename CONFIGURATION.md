# Configuring Shotty

Let's say you've got four different directories you want to serve:

 * A directory with random images (PNGs, JPGs, and GIFs).  There's no rhyme or reason to the filenames, you just want the most recent ones.
 * The directory your favourite game stores screenshots in.  They all have the format `2023-08-31_12:34:56.png` — ISO dates, zero-padded, one-second precision — so they always sort correctly.  (However, they also include smaller thumbnails in that directory, which you don't want.)
 * A directory where your OS throws the screenshots you take.  These are numbered in the awkward `File (n).png` format, e.g. `Screenshot (78).png`, `Screenshot (1041).png`, etc.
 * Your Steam screenshot repository, with screenshots from a bunch of games.

Your configuration might thus look like this:

```elixir
import Config

config :shotty,
  start: true,
  bind: {"0.0.0.0", 4000},
  paths: [
    random_pictures: [
      path: "/path/to/pictures",
      include: ~r/\.(png|jpg|gif)$/
    ],
    my_fav_game: [
      indexer: :sorted,
      path: "/path/to/game/screenshots",
      include: ~r/^\d{4}-.*\.png$/,
      exclude: ~r/_thumbnail\.png$/
    ],
    windows: [
      indexer: :sorted,
      path: "/path/to/user/Pictures/Screenshots",
      include: ~r/^Screenshot \((?<sort_integer>\d+)\).png$/
    ],
    steam: [
      indexer: :steam,
      path: "/path/to/steam/userdata/12345678"
    ]
  ]
```

This configures four paths:

  * `random_pictures` — uses the `mtime` indexer (since we can't rely on the filenames)
  * `my_fav_game` — all included filenames can be sorted reliably, so we use the `sorted` indexer
  * `windows` — we also use `sorted` here, but the `sort_integer` named capture group in our `include` pattern means we sort based on the number in the brackets (and **not** on the raw filename)
  * `steam` — we use the `steam` indexer here, pointing to our Steam userdata directory

For more details about each indexer, read on.

## Indexers

When configuring your paths, you can select one of several indexers:

### `mtime`

The simplest (and default) indexer.  Sorts files by modified time (`mtime`).

Parameters:

 * `path` (required) — the path to read files from
 * `include` (optional) — a regular expression indicating files to serve
 * `exclude` (optional) — a regular expression indicating files to **not** serve

When a request comes in, all files that match `include` and do **not** match `exclude` will be sorted by modified time (`mtime`), with the most recently modified file being file #1.

Because this indexer may have to issue hundreds of `stat` calls on every request (one per file), it can be a bit slow for large directories, especially on virtual or networked filesystems.  (For example, I run this on my Windows system using WSL2, and it can start getting slow when you have thousands of files.)  If this indexer is running slowly, you may wish to use the next indexer instead.

### `sorted`

Sorts files based on filename, or a portion thereof.  Faster than `mtime`, but only works if you can reliably determine the creation order of files just via their filename.

This may be using e.g. a date & time in the filename (e.g. `Screenshot 2023-08-31_20:24:55.png`, or a sequential number (e.g. `Screenshot (312).png`).

The parameters are identical to `mtime`:

 * `path` (required) — the path to read files from
 * `include` (optional) — a regular expression indicating files to serve
 * `exclude` (optional) — a regular expression indicating files to **not** serve

Normally, files are sorted purely based on their entire filename.  However, you can customise this by putting capture groups in the `include` regex:

 * `(?<sort> ... )` — sort alphabetically by the matching group's contents
   * this may be useful if files might have several different prefixes, but still have a portion of the filename that can be reliably sorted on
   * if they all have the same prefix, you can skip this and just sort on the entire filename
 * `(?<sort_integer> ... )` — convert the matching group's contents to an integer and sort numerically
   * this is only needed for non-zero-padded numbers, for example if your screenshot tool produces `Screenshot (99).png` and then `Screenshot (100).png`, since `100` would come first in a normal alphabetical sort

Note that you can freely switch between `sorted` and `mtime` while setting up and testing, since they both use the same parameters, and `mtime` ignores any capture groups in the regular expression.

### `steam`

Designed to handle screenshots taken using the Steam client.

It only takes a single parameter: `path`.  This should point to either the `steam/userdata` directory (which contains several numbered directories for each Steam user active on that system), or to a single one of those numbered directories (if you only want one user's screenshots).

To find the Nth latest screenshot(s) in an efficient manner, the indexer will first check the modified time of every game's screenshot folder, then progress down them (newest to oldest), collecting up to N files, until it has found the Nth oldest file **and** the next directory in the list is **older** than that file.

As such, performance will be quickest when asking for the latest file, and slowest when asking for the oldest; and, the more Steam games you have screenshots for, the slower this indexer will take to begin finding any files at all.  However, on a native filesystem, performance is a non-issue — testing with 2500+ screenshots across 93 games resulted in a range of 15ms to 135ms — and even a slow filesystem like WSL2 can traverse thousands of screenshots within seconds (and runs much faster than e.g. a `find`-based solution).
