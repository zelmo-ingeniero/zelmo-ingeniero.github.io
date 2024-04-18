/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{html,js}"],
  theme: {
    screens: {
      sm: "480px",
      md: "768px",
      lg: "1080px",
    },
    colors: {
      black: "hsl(210, 13%, 3%)",
      white: "hsl(0, 0%, 100%)",
      green: "hsl(120, 43%, 27%)"
    },
    extend: {},
  },
  plugins: [],
};
