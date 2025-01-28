import typography from "@tailwindcss/typography";
import defaultTheme from "tailwindcss/defaultTheme";

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./Sources/Loopwerk/templates/*.swift"],
  theme: {
    container: {
      center: true,
      padding: {
        DEFAULT: '2rem',
        lg: '0',
      },
    },
    screens: {
      lg: "800px",
    },
    colors: {
      transparent: "transparent",
      white: "#eee",
      orange: "#f1a948",
      page: "#222831",
      nav: "#0e1112",
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
          },
        },
      }),
    },
  },
  corePlugins: {
    backgroundOpacity: false,
    textOpacity: false,
  },
  plugins: [typography],
}
