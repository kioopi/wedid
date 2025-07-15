export default LocaleSwitcher = {
  mounted() {
    // Handle locale change events from the server
    this.handleEvent("locale-changed", ({locale, shouldReload = true}) => {
      this.setLocale(locale);
      // Always reload to ensure proper locale application across all components
      if (shouldReload) {
        window.location.reload();
      }
    });

    // Load saved locale on page load and sync with server if different
    const savedLocale = localStorage.getItem("locale");
    const currentLocale = this.el.dataset.currentLocale;
    
    // If there's no saved locale, save the current one
    if (!savedLocale) {
      localStorage.setItem("locale", currentLocale);
      document.documentElement.setAttribute("lang", currentLocale);
    } else if (savedLocale !== currentLocale) {
      // Sync silently without reload for initial load
      this.pushEvent("sync_locale", {locale: savedLocale});
    } else {
      // Ensure document language is set
      document.documentElement.setAttribute("lang", currentLocale);
    }
  },

  setLocale(locale) {
    localStorage.setItem("locale", locale);
    document.documentElement.setAttribute("lang", locale);
  }
};

// Initialize locale immediately when script loads
export function initLocale() {
  const savedLocale = localStorage.getItem("locale");
  if (savedLocale) {
    // Set document language attribute
    document.documentElement.setAttribute("lang", savedLocale);
  } else {
    // Set default language if no saved locale
    document.documentElement.setAttribute("lang", "en");
  }
}

// Export function to change locale programmatically
export function changeLocale(locale) {
  localStorage.setItem("locale", locale);
  document.documentElement.setAttribute("lang", locale);
  
  // Trigger a custom event that LiveView can listen to
  window.dispatchEvent(new CustomEvent("locale-change", { 
    detail: { locale: locale } 
  }));
}