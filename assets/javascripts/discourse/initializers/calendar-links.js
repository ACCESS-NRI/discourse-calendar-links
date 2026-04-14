// assets/javascripts/discourse/initializers/calendar-links.js

import { withPluginApi } from "discourse/lib/plugin-api";
import CalendarLinksModal from "../components/calendar-links-modal";

export default {
  name: "calendar-links",

  initialize(container) {
    withPluginApi((api) => {
      if (
        !api.container.lookup("service:site-settings").calendar_links_enabled
      ) {
        return;
      }

      api.addComposerToolbarPopupMenuOption({
        icon: "calendar-days",
        label: "calendar_links.toolbar_label",
        action: (toolbarEvent) => {
          const modal = container.lookup("service:modal");
          modal.show(CalendarLinksModal, {
            model: {
              onInsert: (htmlBlock) => {
                toolbarEvent.addText(htmlBlock);
              },
            },
          });
        },
      });
    });
  },
};
