# Design Tokens for Admin Panel

## Colors

| Token Name             | Hex              | Tailwind Class / Notes                 |
|------------------------|------------------|----------------------------------------|
| color-primary          | #4F46E5          | bg-indigo-600, text-indigo-600         |
| color-primary-hover    | #4338CA          | (slightly darker indigo)               |
| color-background       | #FFFFFF          | bg-white                               |
| color-background-muted | #F9FAFB          | bg-gray-50 / bg-gray-100 alternative   |
| color-text-primary     | #111827          | text-gray-900                          |
| color-text-secondary   | #6B7280          | text-gray-500 or text-gray-400         |
| color-text-link        | #4338CA          | text-indigo-600                        |
| color-text-disabled    | #9CA3AF          | text-gray-400                          |
| color-border           | #E5E7EB          | border-gray-300                        |
| color-border-active    | #C7D2FE          | border-indigo-300 (focus state)        |
| color-success          | #10B981          | text-green-500                         |
| color-shadow           | rgba(0,0,0,0.05) | shadow color (use shadow-xs or shadow-sm) |

## Border Radius

| Token Name                | Value  | Tailwind Class Example |
|---------------------------|--------|------------------------|
| radius-sm                 | 4px    | rounded-sm             |
| radius-md                 | 8px    | rounded-md             |
| radius-lg                 | 12px   | rounded-lg             |
| radius-full (for avatars) | 9999px | rounded-full           |

- Main cards, input fields and buttons use `rounded-md` (8px).

## Shadows

| Token Name            | Tailwind Utility Example  | Description                           |
|-----------------------|---------------------------|---------------------------------------|
| shadow-xs             | shadow-xs                 | subtle card and input shadow          |
| shadow-sm             | shadow-sm                 | default shadow used on cards          |
| shadow-outline-indigo | ring-1 ring-indigo-300/50 | focus state on input / selection card |

## Spacing & Sizing

| Token Name       | Value | Tailwind Class Example | Description/Use              |
|------------------|-------|------------------------|------------------------------|
| spacing-1        | 4px   | p-1, m-1               | Small gaps, icon text margin |
| spacing-2        | 8px   | p-2, m-2               | General padding, gaps        |
| spacing-3        | 12px  | p-3, m-3               | Medium vertical margin       |
| spacing-4        | 16px  | p-4, m-4               | Larger padding & section gap |
| width-input      | 280px | w-72                   | Width of card payment method |
| height-button    | 40px  | h-10                   | Button height                |
| font-size-base   | 16px  | text-base              | Body text                    |
| font-size-sm     | 14px  | text-sm                | Subtitle, description text   |
| font-size-lg     | 18px  | text-lg                | Section titles, headings     |
| line-height-base | 24px  | leading-6              | Body text readability        |
| icon-size        | 20px  | w-5 h-5                | Small icons                  |

## Typography

| Token Name           | Value | Tailwind Class Example | Description                     |
|----------------------|-------|------------------------|---------------------------------|
| font-weight-normal   | 400   | font-normal            | Paragraph, input text           |
| font-weight-semibold | 600   | font-semibold          | Subheadings, button text        |
| font-weight-bold     | 700   | font-bold              | Main headings, important labels |

---

### Example Usage in TailwindCSS

- Primary Button: `bg-indigo-600 text-white rounded-md h-10 px-4 shadow-xs hover:bg-indigo-700`
- Card Container: `bg-white rounded-md shadow-sm p-4`
- Input with Focus: `border border-gray-300 rounded-md p-2 focus:outline-none focus:ring-1 focus:ring-indigo-300`
- Sidebar Icons: `w-5 h-5 text-gray-500`
- Link Text: `text-indigo-600 font-semibold`

---

This token file serves as the foundation for maintaining consistency throughout the CMS Admin Panel UI, using TailwindCSS 3 utility classes for rapid implementation and scalability.
