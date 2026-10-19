# discourse-calendar-links

A Discourse **theme component** that adds a composer toolbar button to insert calendar links (Google Calendar, Outlook Live, and `.ics` / Apple Calendar) into posts.

## Features

- Toolbar button in the Discourse composer
- Modal form: event title, date, start time, duration, timezone, Zoom URL
- Inserts a formatted HTML block with three calendar links
- ICS download uses a `data:` URI — no server-side file generation needed
- Fully client-side; no backend routes, no plugin install required

## File structure

```
discourse-calendar-links/
├── about.json
├── settings.yml
├── locales/
│   └── en.yml
├── common/
│   └── common.scss
└── javascripts/
    └── discourse/
        ├── api-initializers/
        │   └── calendar-links.js
        ├── components/
        │   └── calendar-links-modal.gjs
        └── lib/
            └── calendar-links-builder.js
```

## Installation

In Discourse admin, go to **Customize → Themes → Install**, choose "From a git repository" and provide the URL of this repository. Then add it as a **component** to whichever theme(s) should have it (or set it to apply to all themes).

Alternatively, you can install this component by uploading a zip or tarball.

## Configuration

In addition to installing the component, you must ensure that the component is enabled on the theme you have loaded.

Do this by going to **Admin → Themes & Components → (THIS COMPONENT) → EDIT**, then include the component on the active theme.

## Customisation notes

### Timezone handling

The current implementation uses IANA offsets for a handful of timezones, these should be browser-detectable.

To add more timezones, see the constant defined in `calendar-links-modal.gjs`.

### HTML sanitisation

Discourse's HTML sanitiser allowlists a specific set of tags and attributes. The inserted block uses `<div>`, `<p>`, `<a>`, `<strong>` — all safe. If you add more markup, verify it against [Discourse's sanitisation config](https://github.com/discourse/discourse/blob/main/lib/pretty_text/allowlister.rb).

### Translations

Theme component strings live in `locales/en.yml` under the `calendar_links` namespace and are referenced in JS/templates via the `themePrefix` helper, e.g. `i18n(themePrefix("calendar_links.field_title"))`. Both `settings` and `themePrefix` are injected globally by the theme compiler — no import needed.

## Development

All calendar URL logic lives in `javascripts/discourse/lib/calendar-links-builder.js` and is pure JS with no Ember dependencies.

## License

Apache Software License 2.0, see LICENSE file for details.
