import typography from "@tailwindcss/typography";
import defaultTheme from "tailwindcss/defaultTheme";

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./Sources/Loopwerk/templates/*.swift"],
  theme: {
    container: {
      center: true,
      padding: {
        DEFAULT: "0",
      },
    },
    screens: {
      sm: "315px",
      lg: "800px",
    },
    colors: {
      inherit: "inherit",
      transparent: "transparent",
      white: "#f1f5f9",
      orange: "#f1a948",
      page: "#1a202b",
      nav: "#0e1112",
      sub: "#252f3f",
      light: "#64748b",
      gray: "#93a3b8",
    },
    extend: {
      fontFamily: {
        helvetica: ["Helvetica", ...defaultTheme.fontFamily.sans],
        ibm: ["IBM Plex Sans", ...defaultTheme.fontFamily.sans],
      },
      typography: theme => ({
        DEFAULT: {
          css: {
            maxWidth: "100%",
            "--tw-prose-body": theme("colors.white"),
            "--tw-prose-headings": theme("colors.white"),
            "--tw-prose-hr": theme("colors.light"),
            "--tw-prose-bullets": theme("colors.gray"),
            "--tw-prose-counters": theme("colors.gray"),
            "--tw-prose-quotes": theme("colors.gray"),
            "--tw-prose-quote-borders": theme("colors.gray"),
            "blockquote p:first-of-type::before": false,
            "blockquote p:last-of-type::after": false,
            blockquote: {
              fontWeight: "normal",
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
              color: theme("colors.white"),
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
    transform: false,
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
};
