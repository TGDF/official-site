const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  plugins: [
    require('@tailwindcss/typography'),
  ],
  content: [
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}',
    './app/components/**/*.{erb,haml,html,slim,rb}'
  ],
  theme: {
    extend: {
      fontFamily: {
        'sans': ['Noto Sans TC', ...defaultTheme.fontFamily.sans],
      },
      typography: (theme) => ({
        white: {
          css: {
            color: theme('colors.white'),
          }
        }
      }),
    }
  }
}
