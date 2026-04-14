# discourse-calendar-links

A Discourse plugin that adds a composer toolbar button to insert calendar links (Google Calendar, Outlook Live, and `.ics` / Apple Calendar) into posts.

## Features

- Toolbar button in the Discourse composer
- Modal form: event title, date, start time, duration, timezone, Zoom URL
- Inserts a formatted HTML block with three calendar links
- ICS download uses a `data:` URI — no server-side file generation needed
- Fully client-side; no additional backend routes required

## File structure

```
discourse-calendar-links/
├── package.json
├── plugin.rb
├── config/
│   ├── settings.yml
│   └── locales/
│       └── client.en.yml
└── assets/
    ├── stylesheets/
    │   └── calendar-links.scss
    └── javascripts/
        └── discourse/
            ├── initializers/
            │   └── calendar-links.js
            ├── components/
            │   ├── calendar-links-modal.gjs
            └── lib/
                └── calendar-links-builder.js
```

## Installation

### Development (docker/discourse-developer setup)

```bash
cd /var/www/discourse/plugins
git clone https://github.com/bschroeter/discourse-calendar-links
```

Restart your dev server. The button will appear in the composer toolbar.

### Production

Add the plugin to your `app.yml` under `hooks > after_code`:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/yourorg/discourse-calendar-links.git
```

Then rebuild: `./launcher rebuild app`

## Configuration

| Setting | Default | Description |
|---|---|---|
| `calendar_links_enabled` | `true` | Enable/disable the plugin globally |

Found in Admin → Settings → Plugins.

## Customisation notes

### Timezone handling

The current implementation uses IANA offsets for a handful of timezones, these should be browser-detectable.

To add more timezones to the plugin, see the constant defined in `calendar-links-modal.gjs`.

### HTML sanitisation
Discourse's HTML sanitiser allowlists a specific set of tags and attributes. The inserted block uses `<div>`, `<p>`, `<a>`, `<strong>` — all safe. If you add more markup, verify it against [Discourse's sanitisation config](https://github.com/discourse/discourse/blob/main/lib/pretty_text/allowlister.rb).

## Development

All calendar URL logic lives in `lib/calendar-links-builder.js` and is pure JS with no Ember dependencies.

## License

MIT