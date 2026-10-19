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

## Usage

1. Open the composer (new topic, new post, or reply) on a theme with this component enabled.
2. Click the **...** (overflow) icon in the composer toolbar, then choose **Insert calendar links**.
3. Fill in the event details in the dialog: title, date, start time, duration, timezone, and a Zoom URL.
4. Click **Insert links**. A block of text is added to your post with links to add the event to Google Calendar, Outlook, or Apple Calendar/ICS, plus the Zoom link.
5. Finish writing your post as normal and submit it — readers can click any of the inserted links to add the event to their own calendar.

Depending on if you are in Markdown or HTML mode you may see the code or the rendered output. Switch between them to confirm your output looks correct.

## Customisation notes

### Timezone handling

The current implementation uses IANA offsets for a handful of timezones, these should be browser-detectable.

To add more timezones, see the constant defined in `calendar-links-modal.gjs`.

### HTML sanitisation

Discourse's HTML sanitiser allowlists a specific set of tags and attributes. The inserted block uses `<div>`, `<p>`, `<a>`, `<strong>` — all safe. If you add more markup, verify it against [Discourse's sanitisation config](https://github.com/discourse/discourse/blob/main/frontend/pretty-text/addon/allow-lister.js).

### Translations

Theme component strings live in `locales/en.yml` under the `calendar_links` namespace and are referenced in JS/templates via the `themePrefix` helper, e.g. `i18n(themePrefix("calendar_links.field_title"))`. Both `settings` and `themePrefix` are injected globally by the theme compiler — no import needed.

## Development

All calendar URL logic lives in `javascripts/discourse/lib/calendar-links-builder.js` and is pure JS with no Ember dependencies.

## License

Apache Software License 2.0, see LICENSE file for details.
