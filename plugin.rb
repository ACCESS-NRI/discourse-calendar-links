# frozen_string_literal: true

# name: discourse-calendar-links
# about: Adds a composer toolbar button to insert Google Calendar, Outlook, and iCal links
# version: 0.1.0
# authors: Ben Schroeter
# url: https://github.com/bschroeter/discourse-calendar-links

enabled_site_setting :calendar_links_enabled

register_asset "stylesheets/calendar-links.scss"
