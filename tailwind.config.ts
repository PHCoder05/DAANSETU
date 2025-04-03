import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: 'class',
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#3182CE', // Blue
          light: '#63B3ED',
          dark: '#2C5282',
          foreground: '#FFFFFF',
        },
        secondary: {
          DEFAULT: '#718096', // Gray
          foreground: '#FFFFFF',
        },
        destructive: {
          DEFAULT: '#E53E3E', // Red
          foreground: '#FFFFFF',
        },
        background: {
          DEFAULT: '#FFFFFF',
          dark: '#171717',
        },
        foreground: {
          DEFAULT: '#171717',
          dark: '#FFFFFF',
        },
        accent: {
          DEFAULT: '#F7FAFC', // Very light gray
          foreground: '#1A202C',
        },
        muted: {
          DEFAULT: '#F1F5F9',
          foreground: '#64748B',
        },
        input: {
          DEFAULT: '#E2E8F0',
        },
        border: {
          DEFAULT: '#E2E8F0',
        },
      },
      fontFamily: {
        sans: ['var(--font-geist-sans)'],
        mono: ['var(--font-geist-mono)'],
      },
      borderRadius: {
        lg: 'var(--radius)',
        md: 'calc(var(--radius) - 2px)',
        sm: 'calc(var(--radius) - 4px)',
      },
      keyframes: {
        "accordion-down": {
          from: { height: "0" },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: "0" },
        },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
      },
    },
  },
  plugins: [],
};

export default config; 