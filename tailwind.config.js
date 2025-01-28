import typography from "@tailwindcss/typography";
import defaultTheme from "tailwindcss/defaultTheme";

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./Sources/Loopwerk/templates/*.swift"],
  theme: {
    container: {
      center: true,
      padding: {
        DEFAULT: '0',
      },
    },
    screens: {
      sm: "315px",
      lg: "800px",
    },
    colors: {
      inherit: "inherit",
      transparent: "transparent",
      white: "#eee",
      orange: "#f1a948",
      page: "#222831",
      nav: "#0e1112",
      sub: "#393e46",
      "gray-1": "#ccc",
      "gray-2": "#9e9d9d",
    },
    extend: {
      fontFamily: {
        helvetica: ["Helvetica", ...defaultTheme.fontFamily.sans],
        anonymous: ["Anonymous Pro", ...defaultTheme.fontFamily.mono],
      },
      typography: (theme) => ({
        DEFAULT: {
          css: {
            maxWidth: '100%',
            '--tw-prose-body': theme('colors.white'),
            '--tw-prose-headings': theme('colors.white'),
            '--tw-prose-code': theme('colors.white'),
            '--tw-prose-pre-bg': '#393e46',
            '--tw-prose-hr': theme('colors.white'),
            a: {
              color: theme('colors.orange'),
              textDecoration: 'none',
              '&:hover': {
                textDecoration: 'underline',
              },
            },
            strong: {
              color: theme('colors.white'),
              fontWeight: '800',
            },
            pre: {
              fontSize: "1rem",
              lineHeight: "1.5rem",
            }
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
  plugins: [typography({ target: 'legacy' })],
}
