// assets/javascripts/discourse/lib/calendar-links-builder.js

const ALLOWED_URL_PROTOCOLS = ["http:", "https:"];

/**
 * Pads a number to 2 digits.
 */
function pad(n) {
  return String(n).padStart(2, "0");
}

/**
 * Formats a Date object to ICS UTC date-time string: YYYYMMDDTHHmmssZ
 */
function toICSDateString(date) {
  return (
    date.getUTCFullYear() +
    pad(date.getUTCMonth() + 1) +
    pad(date.getUTCDate()) +
    "T" +
    pad(date.getUTCHours()) +
    pad(date.getUTCMinutes()) +
    "00Z"
  );
}

/**
 * Parses local date + time strings into UTC Date objects for start and end.
 *
 * @param {string} dateStr   - "YYYY-MM-DD"
 * @param {string} timeStr   - "HH:MM"
 * @param {number} durationMin
 * @param {string} tzOffset  - e.g. "+10:00" or "-05:00" or "Z"
 */
function parseEventDates(dateStr, timeStr, durationMin, tzOffset) {
  // Build an ISO 8601 string the browser can parse with offset
  const iso = `${dateStr}T${timeStr}:00${tzOffset === "Z" ? "Z" : tzOffset}`;
  const start = new Date(iso);
  const end = new Date(start.getTime() + durationMin * 60 * 1000);
  return { start, end };
}

/**
 * Builds a Google Calendar "Add Event" URL.
 */
function buildGoogleCalendarURL({ title, start, end, location, description }) {
  const fmt = toICSDateString;
  const params = new URLSearchParams({
    action: "TEMPLATE",
    text: title,
    dates: `${fmt(start)}/${fmt(end)}`,
    location,
    details: description,
  });
  return `https://calendar.google.com/calendar/render?${params.toString()}`;
}

/**
 * Builds an Outlook Live "Add Event" URL.
 */
function buildOutlookURL({ title, start, end, location, description }) {
  const toISO = (d) => d.toISOString().replace(".000", "");
  const params = new URLSearchParams({
    path: "/calendar/action/compose",
    rru: "addevent",
    startdt: toISO(start),
    enddt: toISO(end),
    subject: title,
    location,
    body: description,
  });
  return `https://outlook.live.com/calendar/0/deeplink/compose?${params.toString()}`;
}

/**
 * Builds a valid ICS file string (RFC 5545).
 */
function buildICSString({ title, start, end, location, description, uid }) {
  const fmt = toICSDateString;
  const escape = (str) =>
    str
      .replace(/\\/g, "\\\\")
      .replace(/;/g, "\\;")
      .replace(/,/g, "\\,")
      .replace(/\n/g, "\\n");

  return [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//discourse-calendar-links//EN",
    "CALSCALE:GREGORIAN",
    "METHOD:PUBLISH",
    "BEGIN:VEVENT",
    `UID:${uid || `cal-${Date.now()}@discourse`}`,
    `DTSTAMP:${fmt(new Date())}`,
    `DTSTART:${fmt(start)}`,
    `DTEND:${fmt(end)}`,
    `SUMMARY:${escape(title)}`,
    `LOCATION:${escape(location)}`,
    `DESCRIPTION:${escape(description)}`,
    "END:VEVENT",
    "END:VCALENDAR",
  ].join("\r\n");
}

/**
 * Builds a data: URI for the ICS so it works without createObjectURL
 * and survives being serialised into post HTML.
 */
function buildICSDataURI(icsString) {
  return `data:text/calendar;charset=utf-8,${encodeURIComponent(icsString)}`;
}

/**
 * Validates a user-supplied URL and returns a normalised, safe string
 * (or null if the URL is missing/malformed/uses a disallowed scheme).
 *
 * This is the single place responsible for deciding whether a URL the
 * user typed (e.g. the Zoom link) is safe to use both as a calendar
 * field and as an `href` attribute value in the HTML block we insert
 * into the composer.
 *
 * @param {string} rawURL
 * @returns {string|null}
 */
export function sanitizeURL(rawURL) {
  if (!rawURL) {
    return null;
  }

  let url;
  try {
    url = new URL(rawURL);
  } catch {
    return null;
  }

  if (!ALLOWED_URL_PROTOCOLS.includes(url.protocol)) {
    return null;
  }

  return url.toString();
}

/**
 * Escapes a string for safe use inside HTML text content or a quoted
 * HTML attribute value.
 *
 * @param {string} str
 * @returns {string}
 */
export function escapeHTML(str) {
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

/**
 * Master function: given event params, returns the three calendar link URLs
 * plus the ICS string itself.
 *
 * @param {object} params
 * @param {string} params.title
 * @param {string} params.dateStr        "YYYY-MM-DD"
 * @param {string} params.timeStr        "HH:MM"
 * @param {number} params.durationMin
 * @param {string} params.tzOffset       e.g. "+10:00"
 * @param {string} params.zoomURL        already-sanitized (see sanitizeURL)
 * @returns {{ googleURL, outlookURL, icsDataURI, icsString }}
 */
export function buildCalendarLinks({
  title,
  dateStr,
  timeStr,
  durationMin,
  tzOffset,
  zoomURL,
}) {
  const description = zoomURL ? `Join Zoom meeting: ${zoomURL}` : "";
  const location = zoomURL || "";

  const { start, end } = parseEventDates(
    dateStr,
    timeStr,
    durationMin,
    tzOffset
  );

  const googleURL = buildGoogleCalendarURL({
    title,
    start,
    end,
    location,
    description,
  });
  const outlookURL = buildOutlookURL({
    title,
    start,
    end,
    location,
    description,
  });
  const icsString = buildICSString({
    title,
    start,
    end,
    location,
    description,
  });
  const icsDataURI = buildICSDataURI(icsString);

  return { googleURL, outlookURL, icsDataURI, icsString };
}

/**
 * Renders the HTML block that gets inserted into the composer.
 * Uses a simple <div> with inline styles so it survives Discourse's
 * HTML sanitiser (allowlisted tags/attributes only).
 *
 * `title` and `zoomURL` are user-supplied and are escaped here before
 * being placed into HTML text content / attribute values. `zoomURL`
 * must already have been through `sanitizeURL` — this function does
 * not validate the scheme, it only escapes for safe HTML output.
 */
export function buildInsertHTML({
  title,
  dateStr,
  timeStr,
  zoomURL,
  googleURL,
  outlookURL,
  icsDataURI,
}) {
  const displayDate = new Date(`${dateStr}T${timeStr}`).toLocaleString(
    undefined,
    {
      weekday: "short",
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    }
  );

  const safeTitle = escapeHTML(title);
  const safeZoomURL = zoomURL ? escapeHTML(zoomURL) : "";
  const fileName =
    title.replace(/\s+/g, "-").replace(/[^a-zA-Z0-9-]/g, "") + ".ics";

  return `<div class="calendar-links-block">
  <p><strong>${safeTitle}</strong> &mdash; ${displayDate}</p>
  <p>
    <a href="${googleURL}" target="_blank" rel="noopener noreferrer">Add to Google Calendar</a> &nbsp;&middot;&nbsp;
    <a href="${outlookURL}" target="_blank" rel="noopener noreferrer">Add to Outlook</a> &nbsp;&middot;&nbsp;
    <a href="${icsDataURI}" download="${fileName}">Download .ics (Apple Calendar / iCal)</a>
  </p>
  ${zoomURL ? `<p><a href="${safeZoomURL}" target="_blank" rel="noopener noreferrer">Join Zoom meeting</a></p>` : ""}
</div>`;
}
