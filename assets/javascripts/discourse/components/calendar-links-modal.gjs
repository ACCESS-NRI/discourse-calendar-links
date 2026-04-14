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
    this.formError = null;

    if (!this.date || !this.time) {
      this.formError = i18n("calendar_links.error_date_required");
      return;
    }

    if (this.zoomURL && !/^https?:\/\//i.test(this.zoomURL)) {
      this.zoomError = i18n("calendar_links.error_zoom_url");
      return;
    }

    const eventTitle =
      this.title.trim() || i18n("calendar_links.default_title");
    const durationMin = parseInt(this.duration, 10) || 60;
    const eventDate = new Date(`${this.date}T${this.time}`);
    const tzOffset = getUTCOffset(this.selectedIana, eventDate);

    const { googleURL, outlookURL, icsDataURI } = buildCalendarLinks({
      title: eventTitle,
      dateStr: this.date,
      timeStr: this.time,
      durationMin,
      tzOffset,
      zoomURL: this.zoomURL.trim(),
    });

    const html = buildInsertHTML({
      title: eventTitle,
      dateStr: this.date,
      timeStr: this.time,
      zoomURL: this.zoomURL.trim(),
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
              {{on "input" (fn this.updateField "date")}}
            />
          </div>
          <div class="cal-field">
            <label for="cal-time">{{i18n "calendar_links.field_time"}}</label>
            <input
              type="time"
              id="cal-time"
              value={{this.time}}
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
              min="5"
              max="480"
              step="5"
              {{on "input" (fn this.updateField "duration")}}
            />
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
