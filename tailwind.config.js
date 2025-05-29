const defaultTheme = require('tailwindcss/defaultTheme')
const colors = require('tailwindcss/colors')

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
      colors: {
        primary: colors.indigo[600],
        'primary-foreground': colors.white,
        secondary: colors.gray[600],
        'secondary-foreground': colors.white,
        destructive: colors.red[600],
        'destructive-foreground': colors.white,
        muted: colors.gray[100],
        'muted-foreground': colors.gray[600],
        accent: colors.pink[600],
        'accent-foreground': colors.white,
        background: colors.white,
        foreground: colors.gray[900],
        border: colors.gray[200],
        'input-background': colors.gray[50],
        // Admin Panel v2 specific colors (prefixed with admin- to avoid conflicts)
        'admin-primary': colors.indigo[600],
        'admin-primary-hover': colors.indigo[700],
        'admin-background': colors.white,
        'admin-background-muted': colors.gray[50],
        'admin-text-primary': colors.gray[900],
        'admin-text-secondary': colors.gray[500],
        'admin-text-link': colors.indigo[700],
        'admin-text-disabled': colors.gray[400],
        'admin-border': colors.gray[200],
        'admin-border-active': colors.indigo[300],
        'admin-success': colors.green[500],
      },
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
      // Admin Panel v2 border radius tokens
      borderRadius: {
        'admin-sm': '0.25rem',
        'admin-md': '0.5rem',
        'admin-lg': '0.75rem',
        'admin-full': '9999px',
      },
      // Admin Panel v2 shadow tokens
      boxShadow: {
        'admin-sm': '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
        'admin': '0 1px 3px 0 rgba(0, 0, 0, 0.05), 0 1px 2px 0 rgba(0, 0, 0, 0.05)',
        'admin-outline-indigo': '0 0 0 1px rgba(147, 197, 253, 0.5)',
      },
      // Admin Panel v2 sizing tokens
      width: {
        'admin-input': '280px',
      },
    }
  }
}
