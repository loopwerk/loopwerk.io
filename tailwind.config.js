import typography from "@tailwindcss/typography";
import defaultTheme from "tailwindcss/defaultTheme";

function hexToRgbTriple(color) {
  if (color === "transparent") return { rgb: "0 0 0", opacity: "0%" };
  const hex = color.replace("#", "");
  const full = hex.length === 3 ? hex.split("").map(c => c + c).join("") : hex;
  const r = parseInt(full.slice(0, 2), 16);
  const g = parseInt(full.slice(2, 4), 16);
  const b = parseInt(full.slice(4, 6), 16);
  return { rgb: `${r} ${g} ${b}` };
}

function modeAwareColors(input) {
  const lightVars = {};
  const darkVars = {};
  const colors = {};
  for (const [name, value] of Object.entries(input)) {
    if (value && typeof value === "object" && "light" in value && "dark" in value) {
      const l = hexToRgbTriple(value.light);
      const d = hexToRgbTriple(value.dark);
      lightVars[`--color-${name}`] = l.rgb;
      darkVars[`--color-${name}`] = d.rgb;
      if (l.opacity) lightVars[`--opacity-${name}`] = l.opacity;
      if (d.opacity) darkVars[`--opacity-${name}`] = d.opacity;
      colors[name] = ({ opacityValue } = {}) => {
        if (opacityValue) {
          if (typeof opacityValue === "string" && opacityValue.startsWith("var(")) {
            return `rgb(var(--color-${name}) / var(--opacity-${name}, ${opacityValue}))`;
          }
          return `rgb(var(--color-${name}) / ${opacityValue})`;
        }
        return `rgb(var(--color-${name}) / var(--opacity-${name}, 1))`;
      };
    } else {
      colors[name] = value;
    }
  }
  return { colors, lightVars, darkVars };
}

const { colors, lightVars, darkVars } = modeAwareColors({
  inherit: "inherit",
  transparent: "transparent",
  orange: { dark: "#f1a948", light: "#d58110" },
  primarytext: { dark: "#f1f5f9", light: "#252f3f" },
  secondarytext: { dark: "#93a3b8", light: "#5F6F84" },
  tertiarytext: { dark: "#64748b", light: "#93a3b8" },
  quotetext: { dark: "#93a3b8", light: "#5F6F84" },
  navlink: { dark: "#93a3b8", light: "#93a3b8" },
  navactivelink: { dark: "#f1f5f9", light: "#f1f5f9" },
  page: { dark: "#1a202b", light: "#f1f5f9" },
  nav: { dark: "#0e1112", light: "#252f3f" },
  codebg: { dark: "#252f3f", light: "#EAECEF" },
  codefg: { dark: "#f1f5f9", light: "#252f3f" },
  divider: { dark: "#64748b", light: "#5F6F84" },
  searchbg: { dark: "#252f3f", light: "#E5E8EA" },
  searchfg: { dark: "#f1f5f9", light: "#252f3f" },
  shadowbg: { dark: "#0e1112", light: "#E5E8EA" },
  asidebg: { dark: "transparent", light: "transparent" },
  asidefg: { dark: "#93a3b8", light: "#5F6F84" },
  searchplaceholder: { dark: "#93a3b8", light: "#93a3b8" },
});

/** @type {import('tailwindcss').Config} */
module.exports = {
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
    colors,
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
    function ({ addBase }) {
      addBase({
        ":root": lightVars,
        ".dark": darkVars,
      });
    },
  ],
};
