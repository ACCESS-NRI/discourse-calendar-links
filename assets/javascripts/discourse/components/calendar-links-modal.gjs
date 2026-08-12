import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import { eq } from "truth-helpers";
import DModal from "discourse/components/d-modal";
import DButton from "discourse/components/d-button";
import { i18n } from "discourse-i18n";
import {
  buildCalendarLinks,
  buildInsertHTML,
  sanitizeURL,
} from "../lib/calendar-links-builder";

const TIMEZONES = [
  { label: "UTC", iana: "UTC" },
  { label: "US Eastern", iana: "America/New_York" },
  { label: "US Central", iana: "America/Chicago" },
  { label: "US Mountain", iana: "America/Denver" },
  { label: "US Pacific", iana: "America/Los_Angeles" },
  { label: "London", iana: "Europe/London" },
  { label: "Paris / Berlin", iana: "Europe/Paris" },
  { label: "Istanbul", iana: "Asia/Istanbul" },
  { label: "Dubai", iana: "Asia/Dubai" },
  { label: "India", iana: "Asia/Kolkata" },
  { label: "Singapore / Hong Kong", iana: "Asia/Singapore" },
  { label: "Tokyo", iana: "Asia/Tokyo" },
  { label: "Sydney", iana: "Australia/Sydney" },
];

// Keep these in sync with the min/max/maxlength attributes on the
// corresponding inputs below.
const TITLE_MAX_LENGTH = 200;
const DURATION_MIN = 5;
const DURATION_MAX = 480;

function getUTCOffset(ianaTimezone, eventDate) {
  const formatter = new Intl.DateTimeFormat("en", {
    timeZone: ianaTimezone,
    timeZoneName: "shortOffset",
  });

  const parts = formatter.formatToParts(eventDate);
  const offsetPart =
    parts.find((p) => p.type === "timeZoneName")?.value ?? "GMT+0";

  const match = offsetPart.match(/GMT([+-])(\d+)(?::(\d+))?/);
  if (!match) return "+00:00";

  const sign = match[1];
  const hours = match[2].padStart(2, "0");
  const minutes = (match[3] ?? "0").padStart(2, "0");
  return `${sign}${hours}:${minutes}`;
}

export default class CalendarLinksModal extends Component {
  @tracked title = "";
  @tracked date = "";
  @tracked time = "";
  @tracked duration = 60;
  @tracked selectedIana =
    Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";
  @tracked zoomURL = "";
  @tracked zoomError = null;
  @tracked durationError = null;
  @tracked formError = null;

  get timezones() {
    return TIMEZONES;
  }

  @action
  onTzChange(event) {
    this.selectedIana = event.target.value;
  }

  @action
  updateField(field, event) {
    this[field] = event.target.value;
  }

  @action
  insertLinks() {
    this.zoomError = null;
    this.durationError = null;
    this.formError = null;

    // Required fields
    if (!this.date || !this.time) {
      this.formError = i18n("calendar_links.error_date_required");
      return;
    }

    // Reject dates/times that don't combine into a real Date (e.g. a
    // browser that doesn't fully support <input type="date"/"time"> and
    // lets malformed text through).
    const eventDate = new Date(`${this.date}T${this.time}`);
    if (isNaN(eventDate.getTime())) {
      this.formError = i18n("calendar_links.error_date_invalid");
      return;
    }

    // Duration must be a finite number within the range advertised by
    // the input's min/max attributes - typed values can bypass the
    // browser's own spinner constraints.
    const durationMin = Number(this.duration);
    if (
      !Number.isFinite(durationMin) ||
      durationMin < DURATION_MIN ||
      durationMin > DURATION_MAX
    ) {
      this.durationError = i18n("calendar_links.error_duration_range");
      return;
    }

    const trimmedTitle = this.title.trim();
    if (trimmedTitle.length > TITLE_MAX_LENGTH) {
      this.formError = i18n("calendar_links.error_title_length");
      return;
    }

    // Validate + normalise the Zoom URL. This also protects against the
    // URL being used to break out of the href="" attribute when it's
    // inserted into the composer HTML.
    let sanitizedZoomURL = "";
    const trimmedZoomURL = this.zoomURL.trim();
    if (trimmedZoomURL) {
      sanitizedZoomURL = sanitizeURL(trimmedZoomURL);
      if (!sanitizedZoomURL) {
        this.zoomError = i18n("calendar_links.error_zoom_url");
        return;
      }
    }

    const eventTitle = trimmedTitle || i18n("calendar_links.default_title");
    const tzOffset = getUTCOffset(this.selectedIana, eventDate);

    const { googleURL, outlookURL, icsDataURI } = buildCalendarLinks({
      title: eventTitle,
      dateStr: this.date,
      timeStr: this.time,
      durationMin,
      tzOffset,
      zoomURL: sanitizedZoomURL,
    });

    const html = buildInsertHTML({
      title: eventTitle,
      dateStr: this.date,
      timeStr: this.time,
      zoomURL: sanitizedZoomURL,
      googleURL,
      outlookURL,
      icsDataURI,
    });

    this.args.model.onInsert(html);
    this.args.closeModal();
  }

  <template>
    <DModal
      @title={{i18n "calendar_links.modal_title"}}
      @closeModal={{@closeModal}}
      class="calendar-links-modal"
    >
      <:body>
        <div class="cal-field">
          <label for="cal-title">{{i18n "calendar_links.field_title"}}</label>
          <input
            type="text"
            id="cal-title"
            value={{this.title}}
            maxlength={{TITLE_MAX_LENGTH}}
            placeholder={{i18n "calendar_links.field_title_placeholder"}}
            {{on "input" (fn this.updateField "title")}}
          />
        </div>

        <div class="cal-field-row">
          <div class="cal-field">
            <label for="cal-date">{{i18n "calendar_links.field_date"}}</label>
            <input
              type="date"
              id="cal-date"
              value={{this.date}}
              required
              {{on "input" (fn this.updateField "date")}}
            />
          </div>
          <div class="cal-field">
            <label for="cal-time">{{i18n "calendar_links.field_time"}}</label>
            <input
              type="time"
              id="cal-time"
              value={{this.time}}
              required
              {{on "input" (fn this.updateField "time")}}
            />
          </div>
        </div>

        <div class="cal-field-row">
          <div class="cal-field">
            <label for="cal-duration">
              {{i18n "calendar_links.field_duration"}}
            </label>
            <input
              type="number"
              id="cal-duration"
              value={{this.duration}}
              min={{DURATION_MIN}}
              max={{DURATION_MAX}}
              step="5"
              {{on "input" (fn this.updateField "duration")}}
            />
            {{#if this.durationError}}
              <p class="cal-error">{{this.durationError}}</p>
            {{/if}}
          </div>
          <div class="cal-field">
            <label for="cal-tz">{{i18n "calendar_links.field_timezone"}}</label>
            <select id="cal-tz" {{on "change" this.onTzChange}}>
              {{#each this.timezones as |tz|}}
                <option
                  value={{tz.iana}}
                  selected={{eq tz.iana this.selectedIana}}
                >
                  {{tz.label}}
                </option>
              {{/each}}
            </select>
          </div>
        </div>

        <div class="cal-field">
          <label for="cal-zoom">{{i18n "calendar_links.field_zoom"}}</label>
          <input
            type="url"
            id="cal-zoom"
            value={{this.zoomURL}}
            placeholder="https://zoom.us/j/..."
            {{on "input" (fn this.updateField "zoomURL")}}
          />
          {{#if this.zoomError}}
            <p class="cal-error">{{this.zoomError}}</p>
          {{/if}}
        </div>

        {{#if this.formError}}
          <p class="cal-error cal-error--global">{{this.formError}}</p>
        {{/if}}
      </:body>

      <:footer>
        <DButton @action={{@closeModal}} @label="cancel" class="btn-flat" />
        <DButton
          @action={{this.insertLinks}}
          @label="calendar_links.insert_button"
          class="btn-primary"
        />
      </:footer>
    </DModal>
  </template>
}
