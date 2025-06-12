# Admin UI Components

## Page Header

### Appearance Description
The page header serves as the primary title area, featuring a clear and bold heading with supporting subtitle text below. It uses text-gray-900 color for the title and text-gray-600 for supplementary text. The spacing below the title (mb-6) ensures clear separation from content sections.

### Example Code

```html
<div class="mb-6">
  <h1 class="text-xl font-semibold text-gray-900 mb-2">Settings</h1>
  <p class="text-gray-600 text-sm">
    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Turpis morbi pulvinar venenatis non.
  </p>
</div>
```

### Usage Guidance
Use for main page titles in the Admin Panel. Maintain consistent margin below (mb-6) to separate from subsequent cards or tabs. Titles should use text-xl font size and semibold weight for clarity. Descriptive text should use text-sm size for better readability.

---

## Card

### Appearance Description

Cards are containers with white background, medium border radius, subtle shadow and an optional border to visually separate content blocks.

### Example Code

```html
<div class="bg-white border border-gray-200 rounded-md shadow-sm">
  <div class="p-6">
    <div class="mb-6">
      <h3 class="text-base font-medium text-gray-900 mb-2">Personal Information</h3>
      <p class="text-gray-600 text-sm">Update your personal details and contact information</p>
    </div>
    <!-- Card content -->
  </div>
</div>
```

### Usage Guidance

Use cards to group related UI sections such as form areas or payment info. Consistent padding (p-6) is recommended inside cards to create breathing room. Cards can contain headers, content sections, and footers. Card headers within the content should use text-base font-medium for titles and text-sm for descriptions.

---

## Card Content

### Appearance Description

The card content is the main content area inside a Card with spacing that ensures readability and neat layout.

### Example Code

```html
<div class="p-6">
  <div class="flex items-center justify-between mb-4">
    <div>
      <h3 class="text-base font-medium text-gray-900">
        Subscription Plan: <span class="text-blue-600">Standard</span>
      </h3>
      <p class="text-gray-600 text-sm">Monthly Plan</p>
    </div>
    <button class="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium">Cancel Subscription</button>
  </div>
  
  <div class="flex items-center justify-between py-4 border-t border-gray-200">
    <div>
      <p class="text-gray-900 text-sm">
        Your next payment is <span class="font-semibold">$59.00 USD</span>, to be charged on
        <span class="font-semibold">April 08, 2022</span>
      </p>
    </div>
    <div>
      <p class="text-gray-600 text-sm">Your payment will be automatically renewed each month</p>
    </div>
  </div>
</div>
```

### Usage Guidance

Use consistent padding (p-6) and add vertical spacing between child content elements with margin-bottom (mb-4) for clear separation. Use border-t for separating sections within the card content. Text should use text-sm size for better readability.

---

## Sidebar Header

### Appearance Description

Sidebar header contains the branding or setup action. It uses prominent blue-600 color for buttons and a clean white background with border-r border-gray-200.

### Example Code

```html
<div class="px-4 py-3 border-b border-gray-200 h-16 flex items-center">
  <div class="flex items-center gap-2">
    <div class="w-7 h-7 bg-blue-600 rounded-full flex items-center justify-center">
      <div class="w-3.5 h-3.5 bg-white rounded-full"></div>
    </div>
    <span class="text-lg font-semibold text-gray-900">ClarityOI</span>
  </div>
</div>

<div class="px-3 py-3">
  <button class="w-full bg-blue-600 hover:bg-blue-700 text-white text-sm h-9 px-4 rounded-md flex items-center justify-center">
    <i class="w-4 h-4 mr-2"><!-- Plus icon --></i>
    Connect New Account
  </button>
</div>
```

### Usage Guidance

Use sidebar header for main sidebar actions or branding. Ensure button has sufficient hit area and stands out with strong background color. The logo should be simple and recognizable. Use h-16 for consistent header height.

---

## Sidebar Item

### Appearance Description

Sidebar items are vertically stacked links with icon and text. They use text-gray-900 for active and text-gray-600 for inactive states, with left padding and hover background to highlight.

### Example Code

```html
<div class="flex items-center gap-2.5 px-2.5 py-1.5 text-gray-900 bg-gray-50 rounded-md">
  <i class="w-4 h-4"><!-- Home icon --></i>
  <span class="font-medium text-sm">Dashboard</span>
</div>

<div class="flex items-center gap-2.5 px-2.5 py-1.5 text-gray-600 hover:text-gray-900 hover:bg-gray-50 rounded-md cursor-pointer">
  <i class="w-4 h-4"><!-- Chart icon --></i>
  <span class="text-sm">Performance</span>
</div>
```

### Usage Guidance

Use consistent padding (px-2.5 py-1.5) for click targets. Highlight active items with bg-gray-50 and text-gray-900. Inactive items should have text-gray-600 with hover:text-gray-900 and hover:bg-gray-50. Use gap-2.5 for spacing between icon and text. Text should be text-sm size.

---

## Sidebar Section

### Appearance Description

Sidebar sections group related navigation items with a header label in uppercase. Items within a section are stacked vertically with consistent spacing.

### Example Code

```html
<div class="space-y-0.5">
  <div class="px-2.5 py-1 text-xs font-medium text-gray-500 uppercase tracking-wide">ANALYTICS</div>
  <div class="flex items-center gap-2.5 px-2.5 py-1.5 text-gray-600 hover:text-gray-900 hover:bg-gray-50 rounded-md cursor-pointer">
    <i class="w-4 h-4"><!-- Chart icon --></i>
    <span class="text-sm">Performance</span>
  </div>
  <div class="flex items-center gap-2.5 px-2.5 py-1.5 text-gray-600 hover:text-gray-900 hover:bg-gray-50 rounded-md cursor-pointer">
    <i class="w-4 h-4"><!-- Target icon --></i>
    <span class="text-sm">Hotjar</span>
    <span class="ml-auto bg-blue-100 text-blue-700 text-xs px-1.5 py-0.5 h-5 rounded-md">
      NEW
    </span>
  </div>
</div>
```

### Usage Guidance

Use uppercase text-xs font-medium text-gray-500 for section headers with tracking-wide for letter spacing. Maintain consistent spacing between sections (mt-4) and items within sections (space-y-0.5). Badge indicators should be positioned with ml-auto.

---

## Header Navigation

### Appearance Description

Header navigation includes search, notification icons, and user profile elements aligned horizontally with subtle spacing and interactive states.

### Example Code

```html
<header class="bg-white border-b border-gray-200 h-16 flex items-center px-6">
  <div class="flex items-center justify-between w-full">
    <div class="flex items-center gap-4">
      <div class="relative">
        <i class="w-4 h-4 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"><!-- Search icon --></i>
        <input
          type="text"
          placeholder="Type to search"
          class="pl-9 pr-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent w-72 text-sm h-9"
        />
      </div>
    </div>
    <div class="flex items-center gap-3">
      <button class="h-8 w-8 flex items-center justify-center rounded-md hover:bg-gray-100">
        <i class="w-4 h-4 text-gray-500"><!-- Message icon --></i>
      </button>
      <button class="h-8 w-8 flex items-center justify-center rounded-md hover:bg-gray-100">
        <i class="w-4 h-4 text-gray-500"><!-- Bell icon --></i>
      </button>
      <div class="w-8 h-8 bg-gray-400 rounded-full"></div>
    </div>
  </div>
</header>
```

### Usage Guidance

Position search input on the left with an icon inside. Use ghost buttons for notification icons. Keep consistent spacing (gap-3) between elements. Use rounded-full for user avatar. Header should have fixed height (h-16) for consistency.

---

## Dropdown Menu

### Appearance Description

Dropdown menus provide a clean interface for additional options with a trigger button and dropdown content.

### Example Code

```html
<div class="relative">
  <button class="flex items-center text-sm px-3 py-1.5 rounded hover:bg-gray-100">
    Sort by: Recent <i class="w-4 h-4 ml-1"><!-- ChevronDown icon --></i>
  </button>
  <div class="absolute right-0 mt-1 w-40 bg-white border border-gray-200 rounded-md shadow-lg py-1 z-10 hidden">
    <a href="#" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">Recent</a>
    <a href="#" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">Oldest</a>
    <a href="#" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">Amount</a>
  </div>
</div>
```

### Usage Guidance

Trigger elements should indicate dropdown functionality (e.g., with ChevronDown icon). Menu items should have consistent styling (px-4 py-2) and sufficient padding for clickable area. Use text-sm for all text elements. Add the 'hidden' class to hide the dropdown by default, and use JavaScript to toggle visibility.

---

## Avatar

### Appearance Description

Avatars are circular elements with fixed size, used for user profiles or placeholders.

### Example Code

```html
<div class="w-8 h-8 bg-gray-400 rounded-full"></div>
```

### Usage Guidance

Use consistent sizing (w-8 h-8 for header, potentially larger elsewhere). For image avatars, add an img tag with object-cover to maintain aspect ratio:

```html
<div class="w-8 h-8 rounded-full overflow-hidden">
  <img src="avatar.jpg" alt="User avatar" class="w-full h-full object-cover" />
</div>
```

For placeholder avatars, use bg-gray-400 or similar neutral color.

---

## Icon

### Appearance Description

Icons are used throughout the UI, with different sizes depending on context, with text color classes to adapt color dynamically.

### Example Code

```html
<i class="w-4 h-4"><!-- Home icon SVG or icon font --></i>
<i class="w-4 h-4 mr-2"><!-- Plus icon SVG or icon font --></i>
<i class="w-4 h-4 text-gray-500"><!-- Bell icon SVG or icon font --></i>
```

### Usage Guidance

Use consistent icon system (SVG icons or icon font). Maintain standard sizes: w-5 h-5 for larger navigation elements, w-4 h-4 for most UI contexts including buttons. Add appropriate margin (mr-2) when used alongside text. Use text color classes (text-gray-500, text-blue-600) to control icon colors.

---

## Table

### Appearance Description

Tables provide structured data display with headers and rows.

### Example Code

```html
<table class="w-full border-collapse">
  <thead>
    <tr class="border-b border-gray-200">
      <th class="text-left py-3 px-4 text-sm font-medium text-gray-500">Invoice</th>
      <th class="text-left py-3 px-4 text-sm font-medium text-gray-500">Date</th>
      <th class="text-left py-3 px-4 text-sm font-medium text-gray-500">Amount</th>
      <th class="text-left py-3 px-4 text-sm font-medium text-gray-500">Status</th>
      <th class="w-12 py-3 px-4 text-sm font-medium text-gray-500"></th>
    </tr>
  </thead>
  <tbody>
    <tr class="border-b border-gray-200">
      <td class="py-3 px-4 text-sm font-medium">Standard Plan - Feb 2022</td>
      <td class="py-3 px-4 text-sm">07 February, 2022</td>
      <td class="py-3 px-4 text-sm">$59.00</td>
      <td class="py-3 px-4 text-sm">
        <div class="flex items-center gap-2">
          <div class="w-2 h-2 bg-green-500 rounded-full"></div>
          <span class="text-green-700">Complete</span>
        </div>
      </td>
      <td class="py-3 px-4 text-sm">
        <div class="relative">
          <button class="p-1 rounded-md hover:bg-gray-100">
            <i class="w-4 h-4"><!-- MoreHorizontal icon --></i>
          </button>
          <!-- Dropdown menu (hidden by default) -->
          <div class="absolute right-0 mt-1 w-40 bg-white border border-gray-200 rounded-md shadow-lg py-1 z-10 hidden">
            <a href="#" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">Download</a>
            <a href="#" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">View Details</a>
          </div>
        </div>
      </td>
    </tr>
    <!-- More rows -->
  </tbody>
</table>
```

### Usage Guidance

Use consistent padding (py-3 px-4) for all cells. Use text-sm for all text. Table headers should use font-medium text-gray-500. For status indicators, combine a colored dot (w-2 h-2 bg-green-500 rounded-full) with text. Add action buttons in the last column with appropriate dropdown menus.

---

## Input

### Appearance Description

Input fields have white backgrounds, subtle border with border-gray-300, rounded corners (rounded-md), and focus states with ring-2 ring-blue-500. Standard inputs include a label above the input.

### Example Code

```html
<div class="space-y-2">
  <label for="firstName" class="text-sm font-medium text-gray-900">
    First Name
  </label>
  <input
    id="firstName"
    type="text"
    placeholder="Enter your first name"
    class="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
  />
</div>
```

### Usage Guidance

Always use labels with inputs for accessibility. Connect labels and inputs using matching 'for' and 'id' attributes. Use sufficient padding (px-3 py-2) for touch targets and typing comfort. Include placeholder text for guidance. Define appropriate width based on context (w-full for form fields). Use focus:outline-none focus:ring-2 focus:ring-blue-500 for accessible focus states. Use text-sm for consistent text size.

For search inputs that include an icon:

```html
<div class="relative">
  <i class="w-4 h-4 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"><!-- Search icon --></i>
  <input
    type="text"
    placeholder="Type to search"
    class="pl-9 pr-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent w-72 text-sm"
  />
</div>
```

---

## Button

### Appearance Description

Buttons come in various styles (primary, outline, ghost) and sizes. They can include icons and text.

### Example Code

```html
<!-- Primary Button -->
<button class="w-full bg-blue-600 hover:bg-blue-700 text-white text-sm h-9 px-4 rounded-md flex items-center justify-center">
  <i class="w-4 h-4 mr-2"><!-- Plus icon --></i>
  Connect New Account
</button>

<!-- Outline Button -->
<button class="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium">
  Cancel Subscription
</button>

<!-- Ghost Button -->
<button class="flex items-center text-sm px-3 py-1.5 rounded hover:bg-gray-100">
  Sort by: Recent <i class="w-4 h-4 ml-1"><!-- ChevronDown icon --></i>
</button>

<!-- Icon Button -->
<button class="h-8 w-8 flex items-center justify-center rounded-md hover:bg-gray-100">
  <i class="w-4 h-4 text-gray-500"><!-- MessageSquare icon --></i>
</button>
```

### Usage Guidance

Use primary buttons (bg-blue-600) for main actions. Use outline buttons for secondary actions. Use ghost buttons for tertiary actions or in compact spaces. Include icons where appropriate to enhance meaning. Size appropriately based on context and available space. Use text-sm for consistent text size.

## Tabs

### Appearance Description

Tabs organize content into different sections that can be switched between, with proper accessibility attributes for screen readers and keyboard navigation.

### Example Code

```html
<div class="h-10 items-center justify-center rounded-md p-1 text-muted-foreground grid w-full grid-cols-6 bg-gray-100">
  <button class="inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm">Profile</button>
  <button class="inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm">Password</button>
  <button class="inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm">Team</button>
  <button class="inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm">Notification</button>
  <button class="inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm">Billing Details</button>
  <button class="inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm">Integration</button>
</div>

<!-- Tab Content (only the active one should be displayed) -->
<div class="space-y-6">
  <!-- Tab panels go here -->
</div>
```

### Usage Guidance

Use tabs for organizing related content that doesn't need to be visible simultaneously.

For styling: active tabs use `data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm`, while all tabs have consistent padding (`px-3 py-1.5`) and text size (`text-sm font-medium`).

Use the `data-[state=active]` attribute selectors for applying different styles to active tabs.

## Badge

### Appearance Description

Badges are small indicators used to highlight status, counts, or labels.

### Example Code

```html
<span class="ml-auto bg-blue-100 text-blue-700 text-xs px-1.5 py-0.5 h-5 rounded-md">
  NEW
</span>

<span class="ml-auto bg-gray-200 text-gray-700 text-xs px-1.5 py-0.5 h-5 rounded-md">
  15
</span>
```

### Usage Guidance

Use badges sparingly to highlight important information. Position with ml-auto when used in navigation items. Use appropriate color combinations for different states (blue for new features, gray for counts, etc.). Keep text concise and uppercase for emphasis. Use consistent sizing with px-1.5 py-0.5 h-5 and text-xs.
