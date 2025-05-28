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
      // Design tokens for admin v2 panel
      colors: theme => ({
        primary: theme('colors.indigo.600'),
        'primary-foreground': theme('colors.white'),
        secondary: theme('colors.gray.600'),
        'secondary-foreground': theme('colors.white'),
        destructive: theme('colors.red.600'),
        'destructive-foreground': theme('colors.white'),
        muted: theme('colors.gray.100'),
        'muted-foreground': theme('colors.gray.600'),
        accent: theme('colors.pink.600'),
        'accent-foreground': theme('colors.white'),
        background: theme('colors.white'),
        foreground: theme('colors.gray.900'),
        border: theme('colors.gray.200'),
        'input-background': theme('colors.gray.50'),
      }),
      fontFamily: {
        sans: ['Noto Sans TC', ...defaultTheme.fontFamily.sans],
      },
      typography: (theme) => ({
        white: {
          css: {
            '--tw-prose-body': theme('colors.gray[200]'),
            '--tw-prose-headings': theme('colors.gray[100]'),
            '--tw-prose-lead': theme('colors.gray[300]'),
            '--tw-prose-links': theme('colors.gray[100]'),
            '--tw-prose-bold': theme('colors.gray[100]'),
            '--tw-prose-counters': theme('colors.gray[400]'),
            '--tw-prose-bullets': theme('colors.gray[600]'),
            '--tw-prose-hr': theme('colors.gray[700]'),
            '--tw-prose-quotes': theme('colors.gray[100]'),
            '--tw-prose-quote-borders': theme('colors.gray[700]'),
            '--tw-prose-captions': theme('colors.gray[300]'),
            '--tw-prose-code': theme('colors.gray[100]'),
            '--tw-prose-pre-code': theme('colors.gray[900]'),
            '--tw-prose-pre-bg': theme('colors.gray[100]'),
            '--tw-prose-th-borders': theme('colors.gray[700]'),
            '--tw-prose-td-borders': theme('colors.gray[800]'),
          }
        }
      }),
    }
  }
}
