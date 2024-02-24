import Config

config :shotty,
  start: true,
  bind: {"0.0.0.0", 4000},
  paths: [
    ffxiv: [
      indexer: :sorted,
      path: "c:/Users/wisq/Pictures/ffxiv",
      include: ~r/^\d{4}-.*\.png$/,
      exclude: ~r/_original\.png$/
    ],
    genshin: [
      indexer: :mtime,
      path: "g:/genshin/Genshin Impact/Genshin Impact game/ScreenShot",
      include: ~r/\.png$/
    ],
    obs: [
      indexer: :sorted,
      path: "v:/obs",
      include: ~r/Screenshot \d{4}-.*\.png$/
    ],
    steam: [
      indexer: :steam,
      path: "g:/steam/userdata/33784271"
    ],
    vlc: [
      indexer: :sorted,
      path: "c:/Users/wisq/Pictures",
      include: ~r/^vlcsnap-\d{4}-.*\.png$/
    ],
    windows: [
      indexer: :sorted,
      path: "c:/Users/wisq/Pictures/Screenshots",
      include: ~r/^Screenshot \((?<sort_integer>\d+)\).png$/
    ]
  ]
