import typography from "@tailwindcss/typography";
import defaultTheme from "tailwindcss/defaultTheme";

/** @type {import('tailwindcss').Config} */
module.exports = require("tailwind-mode-aware-colors")({
  darkMode: "selector",
  content: ["./Sources/Loopwerk/templates/*.swift"],
  theme: {
    container: {
      center: true,
      padding: {
        DEFAULT: "0",
        lg: "20px",
      },
    },
    screens: {
      sm: "315px",
      lg: "740px",
    },
    colors: {
      inherit: "inherit",
      transparent: "transparent",
      orange: "#f1a948",
      primarytext: { dark: "#f1f5f9", light: "#252f3f" },
      secondarytext: { dark: "#93a3b8", light: "#5F6F84" },
      tertiarytext: { dark: "#64748b", light: "#93a3b8" },
      quotetext: { dark: "#93a3b8", light: "#5F6F84" },
      navlink: { dark: "#93a3b8", light: "#93a3b8" },
      navactivelink: { dark: "#f1f5f9", light: "#f1f5f9" },
      page: { dark: "#1a202b", light: "#f1f5f9" },
      nav: { dark: "#0e1112", light: "#252f3f" },
      codebg: { dark: "#252f3f", light: "#E5E8EA" },
      codefg: { dark: "#f1f5f9", light: "#252f3f" },
      divider: { dark: "#64748b", light: "#5F6F84" },
      searchbg: { dark: "#252f3f", light: "#E5E8EA" },
      searchfg: { dark: "#f1f5f9", light: "#252f3f" },
      shadowbg: { dark: "#0e1112", light: "#E5E8EA" },
      asidebg: { dark: "transparent", light: "transparent" },
      asidefg: { dark: "#93a3b8", light: "#5F6F84" },
      searchplaceholder: { dark: "#93a3b8", light: "#93a3b8" },
    },
    extend: {
      fontFamily: {
        main: ['"Main Sans"', ...defaultTheme.fontFamily.sans],
        title: ['"Title Serif"', ...defaultTheme.fontFamily.serif],
      },
      typography: theme => ({
        DEFAULT: {
          css: {
            maxWidth: "100%",
            "--tw-prose-body": theme("colors.primarytext"),
            "--tw-prose-headings": theme("colors.primarytext"),
            "--tw-prose-hr": theme("colors.tertiarytext"),
            "--tw-prose-bullets": theme("colors.secondarytext"),
            "--tw-prose-counters": theme("colors.secondarytext"),
            "--tw-prose-quotes": theme("colors.quotetext"),
            "--tw-prose-quote-borders": theme("colors.orange"),
            "blockquote p:first-of-type::before": false,
            "blockquote p:last-of-type::after": false,
            blockquote: {
              fontStyle: "normal",
              borderInlineStartWidth: "2px",
            },
            a: {
              color: theme("colors.orange"),
              textDecoration: "none",
              fontWeight: "400",
              "&:hover": {
                textDecoration: "underline",
              },
            },
            strong: {
              color: "inherit",
              fontWeight: "800",
            },
          },
        },
      }),
    },
  },
  corePlugins: {
    contain: false,
    ringWidth: false,
    backdropFilter: false,
    filter: false,
    backgroundOpacity: false,
    textOpacity: false,
  },
  plugins: [
    typography({ target: "legacy" }),

    function ({ addBase, theme }) {
      function extractColorVars(colorObj, colorGroup = "") {
        return Object.keys(colorObj).reduce((vars, colorKey) => {
          const value = colorObj[colorKey];

          const newVars =
            typeof value === "string"
              ? { [`--color${colorGroup}-${colorKey}`]: value }
              : extractColorVars(value, `-${colorKey}`);

          return { ...vars, ...newVars };
        }, {});
      }

      addBase({
        ":root": extractColorVars(theme("colors")),
      });
    },
  ],
});
