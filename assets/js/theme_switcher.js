export default ThemeSwitcher = {
  getActiveButton(theme) {
    return this.el.querySelector(`[data-set-theme='${theme}']`);
  },

  highlightButton(button) {
    if (button) {
      this.unhighlightButton();
      button.classList.add("btn-active", "border-primary");
    }
  },

  unhighlightButton() {
    this.el.querySelectorAll(".btn-active").forEach((button) => {
      button.classList.remove("btn-active", "border-primary");
    });
  },

  mounted() {
    loadTheme((theme) => {
      this.highlightButton(this.getActiveButton(theme));
    });

    this.el.addEventListener("change", (event) => {
      this.newThemeSelected(event, (selectedTheme) => {
        setTheme(selectedTheme);
        this.highlightButton(this.getActiveButton(selectedTheme));
      });
    });
  },

  newThemeSelected({ target: target }, callback) {
    if (target.name === "theme-dropdown") {
      const selectedTheme = target.getAttribute("data-set-theme");
      if (selectedTheme) {
        callback(selectedTheme);
      }
    }
  },

  updated() {
    loadTheme((theme) => {
      this.highlightButton(this.getActiveButton(theme));
    });
  },
};

function loadTheme(onLoaded) {
  const savedTheme = localStorage.getItem("theme");
  if (savedTheme) {
    onLoaded(savedTheme || "light");
  }
}

function setTheme(theme) {
  document.documentElement.setAttribute("data-theme", theme);
  localStorage.setItem("theme", theme);
}

export function initTheme() {
  loadTheme(setTheme);
}
