// javascripts/discourse/api-initializers/calendar-links.js

import { apiInitializer } from "discourse/lib/api";
import CalendarLinksModal from "../components/calendar-links-modal";

export default apiInitializer((api) => {
  if (!settings.calendar_links_enabled) {
    return;
  }

  api.addComposerToolbarPopupMenuOption({
    icon: "calendar-days",
    label: themePrefix("calendar_links.toolbar_label"),
    action: (toolbarEvent) => {
      const modal = api.container.lookup("service:modal");
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
