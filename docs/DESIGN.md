 # Design Tokens

 This document defines the core design tokens for the TailwindCSS-based admin panel (variant `v2`).
 Tokens are organized by category and map to Tailwind theme values. Use these consistently to maintain a unified UI.

 ---

 ## Colors

 | Token                        | Tailwind Key             | Value    |
 |------------------------------|--------------------------|----------|
 | `primary`                    | `colors.indigo.600`      | `#4F46E5`|
 | `primary-foreground`         | `colors.white`           | `#FFFFFF`|
 | `secondary`                  | `colors.gray.600`        | `#4B5563`|
 | `secondary-foreground`       | `colors.white`           | `#FFFFFF`|
 | `destructive`                | `colors.red.600`         | `#DC2626`|
 | `destructive-foreground`     | `colors.white`           | `#FFFFFF`|
 | `muted`                      | `colors.gray.100`        | `#F3F4F6`|
 | `muted-foreground`           | `colors.gray.600`        | `#4B5563`|
 | `accent`                     | `colors.pink.600`        | `#DB2777`|
 | `accent-foreground`          | `colors.white`           | `#FFFFFF`|
 | `background`                 | `colors.white`           | `#FFFFFF`|
 | `foreground`                 | `colors.gray.900`        | `#111827`|
 | `border`                     | `colors.gray.200`        | `#E5E7EB`|
 | `input-background`           | `colors.gray.50`         | `#F9FAFB`|

 ```js
 // tailwind.config.js
 module.exports = {
   theme: {
     extend: {
       colors: {
         primary: theme => theme('colors.indigo.600'),
         'primary-foreground': theme => theme('colors.white'),
         // ...other tokens
       }
     }
   }
 }
 ```

 ---

 ## Typography

 | Token                    | Tailwind Key         | Value             |
 |--------------------------|----------------------|-------------------|
 | `font-family-sans`       | `font-sans`          | `Noto Sans TC, ...` |
 | `font-size-sm`           | `text-sm`            | 14px (0.875rem)   |
 | `font-size-base`         | `text-base`          | 16px (1rem)       |
 | `font-size-lg`           | `text-lg`            | 18px (1.125rem)   |
 | `font-size-xl`           | `text-xl`            | 20px (1.25rem)    |
 | `font-size-2xl`          | `text-2xl`           | 24px (1.5rem)     |
 | `font-weight-normal`     | `font-normal`        | 400               |
 | `font-weight-medium`     | `font-medium`        | 500               |
 | `font-weight-semibold`   | `font-semibold`      | 600               |
 | `font-weight-bold`       | `font-bold`          | 700               |

 ```js
 // tailwind.config.js
 module.exports = {
   theme: {
     extend: {
       fontFamily: {
         sans: ['Noto Sans TC', 'ui-sans-serif', 'system-ui'],
       }
     }
   }
 }
 ```

 ---

 ## Spacing

 | Token         | Tailwind Key  | Value          |
 |---------------|---------------|----------------|
 | `space-1`     | `space-1`     | 4px (0.25rem)  |
 | `space-2`     | `space-2`     | 8px (0.5rem)   |
 | `space-3`     | `space-3`     | 12px (0.75rem) |
 | `space-4`     | `space-4`     | 16px (1rem)    |
 | `space-5`     | `space-5`     | 20px (1.25rem) |
 | `space-6`     | `space-6`     | 24px (1.5rem)  |
 | `space-8`     | `space-8`     | 32px (2rem)    |

 ---

 ## Border Radius

 | Token          | Tailwind Key    | Value              |
 |----------------|-----------------|--------------------|
 | `radius-sm`    | `rounded-sm`    | 2px (0.125rem)     |
 | `radius-md`    | `rounded-md`    | 6px (0.375rem)     |
 | `radius-lg`    | `rounded-lg`    | 8px (0.5rem)       |
 | `radius-full`  | `rounded-full`  | 9999px             |

 ---

 ## Shadows

 | Token         | Tailwind Key   | Value (example)                               |
 |---------------|----------------|-----------------------------------------------|
 | `shadow-sm`   | `shadow-sm`    | 0 1px 2px rgba(0,0,0,0.05)                    |
 | `shadow`      | `shadow`       | 0 1px 3px rgba(0,0,0,0.1), 0 1px 2px rgba(0,0,0,0.06) |
 | `shadow-md`   | `shadow-md`    | 0 4px 6px rgba(0,0,0,0.1), 0 2px 4px rgba(0,0,0,0.06) |
 | `shadow-lg`   | `shadow-lg`    | 0 10px 15px rgba(0,0,0,0.1), 0 4px 6px rgba(0,0,0,0.05) |
 | `shadow-xl`   | `shadow-xl`    | 0 20px 25px rgba(0,0,0,0.1), 0 10px 10px rgba(0,0,0,0.04) |
 | `shadow-2xl`  | `shadow-2xl`   | 0 25px 50px rgba(0,0,0,0.25)                  |

 ---

 ## Breakpoints

 | Name        | Key   | Value  |
 |-------------|-------|--------|
 | Small       | `sm`  | 640px  |
 | Medium      | `md`  | 768px  |
 | Large       | `lg`  | 1024px |
 | X-Large     | `xl`  | 1280px |
 | 2X-Large    | `2xl` | 1536px |

 ---

 ## Z-Index

 | Token             | Tailwind Key | Value |
 |-------------------|--------------|-------|
 | `z-dropdown`      | `z-50`       | 50    |
 | `z-sticky`        | `z-40`       | 40    |
 | `z-fixed`         | `z-30`       | 30    |

 ---

 ## Motion / Transition

 | Token               | Tailwind Key     | Value                           |
 |---------------------|------------------|---------------------------------|
 | `duration-75`       | `duration-75`    | 75ms                            |
 | `duration-150`      | `duration-150`   | 150ms                           |
 | `duration-300`      | `duration-300`   | 300ms                           |
 | `ease-in-out`       | `ease-in-out`    | cubic-bezier(0.4, 0, 0.2, 1)    |

 ---

 Use these tokens by referencing Tailwind utility classes or by extending your `tailwind.config.js` under `theme.extend`. Keeping this list up-to-date ensures consistency across the admin panel.