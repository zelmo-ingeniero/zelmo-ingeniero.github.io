/** @type {import('tailwindcss').Config} */

export const content = ["./src/**/*.{html,js}", "./src/*.{html,js}"];
export const theme = {
  colors: {
// sm	640px (min-width: 640px)
// md	768px (min-width: 768px)
// lg	1024px	(min-width: 1024px)
// xl	1280px	(min-width: 1280px)
    black: {
      200: "hsl(210, 13%, 9%)",
      300: "hsl(210, 13%, 8%)",
      400: "hsl(210, 13%, 7%)",
      500: "hsl(210, 13%, 6%)",
      600: "hsl(210, 13%, 5%)",
      700: "hsl(210, 13%, 4%)",
      800: "hsl(210, 13%, 3%)",
      900: "hsl(210, 13%, 2%)",
      950: "hsl(210, 13%, 1%)",
    },
    gray: "hsl(0, 0%, 16.47%)",
    white: "hsl(122, 100%, 100%)",
    term: "hsl(120, 100%, 40%)",
    green: {
      100: "hsl(120, 41%, 97%)",
      200: "hsl(120, 52.5%, 92.5%)",
      300: "hsl(120, 47%, 85%)",
      400: "hsl(120, 41%, 58%)",
      500: "hsl(120, 42%, 45%)",
      600: "hsl(120, 46%, 36%)",
      700: "hsl(120, 43%, 27%)",
      800: "hsl(120, 38%, 24%)",
      900: "hsl(122, 36%, 20%)",
      950: "hsl(122, 49%, 10%)",
    },
  },
  extend: {
    animation: {
      "fade-in": "fade-in 0.5s ease-in-out forwards",
      "fade-out": "fade-out 0.5s ease-in-out forwards",
    },
    keyframes: {
      "fade-in": {
        "0%": { opacity: "0%" },
        "100%": { opacity: "100%" },
      },
      "fade-out": {
        "0%": { opacity: "100%" },
        "100%": { opacity: "0%" },
      },
    },
  },
};
