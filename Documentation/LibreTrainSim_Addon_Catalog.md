# Addon catalog

Libre TrainSim can show downloadable content packs in the Content menu. Set the
project setting `game/content/addon_catalog_url` to an HTTP or HTTPS endpoint
that returns JSON.

The catalog can be either a JSON array or an object with an `addons` array:

```json
{
  "addons": [
    {
      "name": "Example Track",
      "version": "1.0.0",
      "url": "https://example.org/libre-trainsim/example-track.pck",
      "file_name": "example-track.pck",
      "description": "Optional text for catalog maintainers"
    }
  ]
}
```

Each entry must include `name` and `url`. `download_url` can be used instead of
`url`, and `display_name` can be used instead of `name`. Downloads are saved to
`user://addons/`; the simulator must be restarted before newly downloaded or
updated packs are loaded.
