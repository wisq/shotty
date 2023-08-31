import Config

config :shotty,
  start: true,
  bind: {"0.0.0.0", 4000},
  paths: [
    ffxiv: [
      path: "/mnt/c/Users/wisq/Pictures/ffxiv",
      include: ~r/\.png$/,
      exclude: ~r/_original\.png$/
    ],
    genshin: [
      path: "/mnt/g/genshin/Genshin Impact/Genshin Impact game/ScreenShot",
      include: ~r/\.png$/
    ],
    obs: [
      path: "/mnt/v/obs",
      include: ~r/Screenshot .*\.png$/
    ],
    steam: [
      path: "/mnt/g/steam/userdata/33784271",
      indexer: :steam
    ],
    vlc: [
      path: "/mnt/c/Users/wisq/Pictures",
      include: ~r/^vlcsnap.*\.png$/
    ],
    windows: [
      path: "/mnt/c/Users/wisq/Pictures/Screenshots",
      include: ~r/^Screenshot .*\.png$/
    ]
  ]
