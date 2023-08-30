import Config

config :shotty,
  start: true,
  bind: {"127.0.0.1", 4000},
  paths: [
    generic: [
      path: "tmp/generic",
      include: ~r/\.png$/,
      exclude: ~r/_excluded\.png$/
    ],
    steam: [
      path: "tmp/steam",
      indexer: :steam
    ]
  ]
