/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./app/**/*.{js,jsx,ts,tsx}", "./components/**/*.{js,jsx,ts,tsx}", "./src/**/*.{js,jsx,ts,tsx}"],
  presets: [require("nativewind/preset")],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        primary: 'rgb(var(--bg-primary) / <alpha-value>)',
        secondary: 'rgb(var(--bg-secondary) / <alpha-value>)',
        
        text: 'rgb(var(--text-primary) / <alpha-value>)',
        'text-sub': 'rgb(var(--text-secondary) / <alpha-value>)',
        
        accent: 'rgb(var(--accent) / <alpha-value>)',
        'accent-up': 'rgb(var(--accent-light) / <alpha-value>)',
        
        border: 'rgb(var(--border) / <alpha-value>)',
        
        success: 'rgb(var(--success) / <alpha-value>)',
        error: 'rgb(var(--error) / <alpha-value>)',

        card: 'rgb(var(--bg-card) / <alpha-value>)',
        'card-secondary': 'rgb(var(--bg-card-secondary) / <alpha-value>)',
        
        sidebar: 'rgb(var(--bg-sidebar) / <alpha-value>)',
      },
    },
  },
  plugins: [],
}
