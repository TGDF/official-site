# Admin UI Components

## Page Header

### Appearance Description
The page header serves as the primary title area, featuring a clear and bold heading with supporting subtitle text below. It uses `admin-text-primary` color for the title and `admin-text-secondary` for supplementary text. The spacing below the title ensures clear separation from content sections.

### Example Code

```html
<header class="mb-6">
  <h1 class="text-lg font-bold text-admin-text-primary">Settings</h1>
  <p class="text-sm text-admin-text-secondary mt-1">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>
</header>
```

### Usage Guidance
Use for main page titles in the CMS Admin Panel. Maintain consistent margin below to separate from subsequent cards or tabs. Titles should use medium-large font size (`text-lg`) and semibold to bold weight for clarity.

---

## Box

### Appearance Description

Boxes are containers with white background `admin-background`, medium border radius (`admin-radius-md`), subtle `admin-shadow-sm` shadow and a 1px `admin-border` border to visually separate content blocks.

### Example Code

```html
<div class="bg-admin-background rounded-admin-md shadow-admin-sm border border-admin-border p-4">
  <!-- content here -->
</div>
```

### Usage Guidance

Use boxes to group related UI sections such as form areas or payment info. Padding is recommended inside boxes to create breathing room (`p-4`). Avoid nested boxes without spacing to maintain clarity.

---

## Box Body

### Appearance Description

The box body is the main content area inside a Box with spacing that ensures readability and neat layout.

### Example Code

```html
<div class="p-4 space-y-4">
  <!-- content elements -->
</div>
```

### Usage Guidance

Use `space-y-4` to add vertical spacing between child content elements for clear separation. Maintains consistent padding within parent Box.

---

## Box Footer

### Appearance Description

The footer area in a box typically contains smaller auxiliary elements such as buttons or status indicators aligned to the right or center.

### Example Code

```html
<footer class="pt-3 border-t border-admin-border flex justify-end space-x-2">
  <!-- footer controls -->
</footer>
```

### Usage Guidance

Use a top border to visually separate footer from body content. Provide consistent vertical padding (`pt-3`). Footer elements generally align right and have horizontal gaps between controls.

---

## Sidebar Header

### Appearance Description

Sidebar header contains the branding or setup action. It uses prominent `admin-primary` color for buttons and icons with spacing `p-4` for comfortable click area.

### Example Code

```html
<div class="flex items-center p-4 bg-admin-background rounded-admin-md">
  <button class="bg-admin-primary text-white rounded-admin-md py-2 px-4 shadow-admin-sm hover:bg-admin-primary-hover">
    + Connect New Account
  </button>
</div>
```

### Usage Guidance

Use sidebar header for main sidebar actions or branding. Ensure button has sufficient hit area and stands out with strong background color and shadow.

---

## Sidebar Item

### Appearance Description

Sidebar items are vertically stacked links with icon and text. They use `admin-text-primary` and `admin-text-secondary` for active and inactive states, with some left padding and hover background to highlight.

### Example Code

```html
<a href="#" class="flex items-center px-4 py-2 rounded-admin-md hover:bg-admin-background-muted text-admin-text-primary">
  <svg class="w-5 h-5 mr-3 text-admin-text-secondary" fill="none" stroke="currentColor" stroke-width="2">...</svg>
  Dashboard
</a>
```

### Usage Guidance

Use consistent padding for click targets. Highlight hovered items with muted background color. Active or selected item text uses `admin-primary` color for emphasis.

---

## Sidebar Treeview

### Appearance Description

Treeview sidebar items feature nesting indicated by indentation and arrow icons. Child items are slightly lighter or secondary in text color.

### Example Code

```html
<div class="pl-6 space-y-1">
  <a href="#" class="flex items-center text-admin-text-secondary hover:text-admin-primary">Sub-item</a>
</div>
```

### Usage Guidance

Indent child items with padding-left. Use color to differentiate parent/child levels, maintaining clear hierarchy. Toggle icons indicate expand/collapse.

---

## Navbar Site Item

### Appearance Description

Navbar site items include icons and badges aligned horizontally with subtle spacing and interactive states using `admin-primary` color for badges or highlights.

### Example Code

```html
<div class="flex items-center space-x-4">
  <button class="relative">
    <svg class="w-6 h-6 text-admin-text-primary">...</svg>
    <span class="absolute -top-1 -right-1 bg-admin-primary text-white rounded-full text-xs px-1">2</span>
  </button>
  <!-- profile avatar / user menu -->
</div>
```

### Usage Guidance

Provide clear visual notification badges on icons. Use `relative` positioning for badges. Keep space between items consistent for tidy layout.

---

## Dropdown

### Appearance Description

Dropdown menus have white background, rounded corners, subtle shadow, and defined border. Dropdown items highlight on hover with background color in `admin-background-muted`.

### Example Code

```html
<div class="relative inline-block text-left">
  <button class="bg-admin-background rounded-admin-md shadow-admin-sm border border-admin-border px-3 py-2">
    Menu
  </button>
  <div class="origin-top-right absolute right-0 mt-2 w-56 rounded-admin-md shadow-admin bg-admin-background border border-admin-border ring-1 ring-black ring-opacity-5">
    <a href="#" class="block px-4 py-2 text-admin-text-primary hover:bg-admin-background-muted">Option 1</a>
    <a href="#" class="block px-4 py-2 text-admin-text-primary hover:bg-admin-background-muted">Option 2</a>
  </div>
</div>
```

### Usage Guidance

Use accessible keyboard and mouse interactions. Dropdown container must have relative positioning. Items must have hover background and sufficient padding for clickable area.

---

## Avatar

### Appearance Description

Avatars are circular images or initials with `admin-radius-full`, fixed size, and optionally a subtle ring or border for emphasis.

### Example Code

```html
<img src="avatar.jpg" alt="User Avatar" class="w-10 h-10 rounded-admin-full object-cover border border-admin-border" />
```

### Usage Guidance

Use consistent sizing `w-10 h-10`. Use `object-cover` to maintain aspect ratio and crop overflow. Add border for distinction on light backgrounds.

---

## Icon

### Appearance Description

Icons are used throughout the UI, sized typically 20px by 20px (`w-5 h-5`), with tailwind text color used to adapt color dynamically.

> Use Font Awesome by default.

### Example Code

```html
<svg class="w-5 h-5 text-admin-text-secondary" fill="none" stroke="currentColor" stroke-width="2" ...></svg>
```

### Usage Guidance

Use SVG icons with `currentColor` stroke/fill for color flexibility through Tailwind text color classes. Maintain consistent sizes.

---

## Table

### Appearance Description

Tables have full width with minimal borders, header with bold text, rows separated by subtle border or background difference. Text uses `admin-text-primary` and `admin-text-secondary` for muted columns.

### Example Code

```html
<table class="w-full border-collapse text-sm text-admin-text-primary">
  <thead>
    <tr class="border-b border-admin-border font-semibold">
      <th class="text-left py-2 px-4">Invoice</th>
      <th class="text-left py-2 px-4">Date</th>
      <th class="text-right py-2 px-4">Amount</th>
      <th class="text-left py-2 px-4">Status</th>
    </tr>
  </thead>
  <tbody>
    <tr class="border-b border-admin-border">
      <td class="py-2 px-4 font-semibold">Standard Plan - Feb 2022</td>
      <td class="py-2 px-4 text-admin-text-secondary">07 February, 2022</td>
      <td class="py-2 px-4 text-right font-semibold">$59.00</td>
      <td class="py-2 px-4 text-green-500">● Complete</td>
    </tr>
    <!-- More rows -->
  </tbody>
</table>
```

### Usage Guidance

Use semantic table markup for accessibility. Keep row padding consistent. Use `border-b` for row separation. Use color tokens for status labels.

---

## Form

### Appearance Description

Forms use vertical layout with consistent spacing between fields, labels aligned left in bold, and input fields with border and rounded corners.

### Example Code

```html
<form class="space-y-4">
  <label class="block font-semibold text-admin-text-primary" for="email">Email</label>
  <input id="email" type="email" class="border border-admin-border rounded-admin-md p-2 w-full focus:ring-1 focus:ring-admin-border-active focus:outline-none" />
  <!-- More fields -->
</form>
```

### Usage Guidance

Use vertical stacking with `space-y-4` for clear separation. Labels should be associated with inputs via `for` attributes. Inputs use consistent padding and correct focus states.

---

## Input

### Appearance Description

Input fields have white backgrounds, subtle border with `admin-border`, medium rounded corners, and shadow focus ring in `admin-primary` color. Font size for input text is `text-base`.

### Example Code

```html
<input class="bg-admin-input-background text-admin-text-primary border border-admin-border rounded-admin-md p-2 text-base focus:outline-none focus:ring-1 focus:ring-admin-border-active" type="text" />
```

### Usage Guidance

Provide sufficient padding for touch targets and typing comfort. Use focus ring for accessibility. Match font size to body text for consistency.

---

## Button

### Appearance Description

Buttons have strong `admin-primary` background, white text, medium rounded corners, fixed height (40px), horizontal padding, and subtle shadow for depth. Hover darkens background.

### Example Code

```html
<button class="bg-admin-primary text-white rounded-admin-md h-10 px-4 shadow-admin-sm hover:bg-admin-primary-hover focus:outline-none focus:ring-2 focus:ring-admin-border-active">
  Save Changes
</button>
```

### Usage Guidance

Use primary buttons for main actions in forms or dialogs. Ensure consistent sizing and contrast for accessibility. Provide hover and focus styles for interaction feedback.
