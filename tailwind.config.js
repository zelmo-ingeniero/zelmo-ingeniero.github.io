/** @type {import('tailwindcss').Config} */

export const content = ["./src/**/*.{html,js}", "./src/*.{html,js}"];
export const theme = {
  screens: {
    sm: "480px",
    md: "768px",
    lg: "1080px",
  },
  colors: {
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
    white: "hsl(0, 0%, 100%)",
    term: "hsl(120, 100%, 40%)",
    green: {
      50: "hsl(111.43, 41.18%, 96.67%)",
      100: "hsl(120, 52.63%, 92.55%)",
      300: "hsl(120, 47.37%, 85.1%)",
      400: "hsl(119.32, 41.12%, 58.04%)",
      500: "hsl(120, 41.99%, 45.29%)",
      600: "hsl(119.29, 45.95%, 36.27%)",
      700: "hsl(120, 43%, 27%)",
      800: "hsl(120, 38.21%, 24.12%)",
      900: "hsl(121.62, 35.92%, 20.2%)",
      950: "hsl(122.4, 49.02%, 10%)",
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
