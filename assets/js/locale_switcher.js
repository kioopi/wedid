export default LocaleSwitcher = {
  mounted() {
    // Handle locale change events from the server
    this.handleEvent("locale-changed", ({ locale, shouldReload = true }) => {
      this.setLocale(locale);

      if (shouldReload) {
        // Reload with a URL parameter to ensure the server picks up the change
        this.reloadWithLocale(locale);
      }
    });

    this.ensureCorrectLocale();
  },

  selectedLocale() {
    return this.el.dataset.currentLocale;
  },

  setLocale(locale) {
    localStorage.setItem("locale", locale);
    document.documentElement.setAttribute("lang", locale);
  },

  ensureCorrectLocale() {
    const locale = deviceLocale();

    setDeviceLocale(locale);

    if (this.selectedLocale() !== locale) {
      this.pushEvent("sync_locale", { locale });
    }
  },

  setLocaleCookie(locale) {
    const expires = new Date();
    expires.setTime(expires.getTime() + 365 * 24 * 60 * 60 * 1000); // 1 year
    document.cookie = `locale=${locale}; path=/; expires=${expires.toUTCString()}`;
  },

  reloadWithLocale(locale) {
    const url = new URL(window.location);
    url.searchParams.set("locale", locale);
    setTimeout(() => {
      window.location.href = url.toString();
    }, 100);
  },
};

let localeLinksInitialized = false;

function deviceLocale() {
  return localStorage.getItem("locale") || "de";
}

function setDeviceLocale(locale) {
  localStorage.setItem("locale", locale);
  document.documentElement.setAttribute("lang", locale);
}

function attachLocaleLinkHandlers() {
  if (localeLinksInitialized) {
    return;
  }

  localeLinksInitialized = true;

  document.addEventListener(
    "click",
    (event) => {
      const target = event.target.closest("[data-locale-link]");

      if (!target) {
        return;
      }

      const { locale } = target.dataset;

      if (locale) {
        setDeviceLocale(locale);
      }
    },
    true,
  );
}

// Initialize locale immediately when script loads
export function initLocale() {
  document.documentElement.setAttribute("lang", deviceLocale());
  attachLocaleLinkHandlers();
}

// Export function to change locale programmatically
export function changeLocale(locale) {
  setDeviceLocale(locale);

  // Trigger a custom event that LiveView can listen to
  window.dispatchEvent(
    new CustomEvent("locale-change", {
      detail: { locale: locale },
    }),
  );
}
