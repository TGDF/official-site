# Admin UI Components

## Page Header

### Appearance Description
The page header serves as the primary title area, featuring a clear and bold heading with supporting subtitle text below. It uses text-gray-900 color for the title and text-gray-600 for supplementary text. The spacing below the title (mb-6) ensures clear separation from content sections.

### Example Code

```html
<div class="mb-6">
  <h1 class="text-2xl font-semibold text-gray-900 mb-2">Settings</h1>
  <p class="text-gray-600">
    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Turpis morbi pulvinar venenatis non.
  </p>
</div>
```

### Usage Guidance
Use for main page titles in the Admin Panel. Maintain consistent margin below (mb-6) to separate from subsequent cards or tabs. Titles should use text-2xl font size and semibold weight for clarity.

---

## Card

### Appearance Description

Cards are containers with white background, medium border radius, subtle shadow and an optional border to visually separate content blocks. They use the Card component from the UI library.

### Example Code

```html
<Card>
  <CardContent className="p-6">
    <h3 className="text-lg font-medium text-gray-900 mb-4">Profile Settings</h3>
    <p className="text-gray-600">Profile settings content would go here.</p>
  </CardContent>
</Card>
```

### Usage Guidance

Use cards to group related UI sections such as form areas or payment info. Consistent padding (p-6) is recommended inside cards to create breathing room. Cards can contain headers, content sections, and footers.

---

## Card Content

### Appearance Description

The card content is the main content area inside a Card with spacing that ensures readability and neat layout.

### Example Code

```html
<CardContent className="p-6">
  <div className="flex items-center justify-between mb-4">
    <div>
      <h3 className="text-lg font-medium text-gray-900">
        Subscription Plan: <span className="text-blue-600">Standard</span>
      </h3>
      <p className="text-gray-600">Monthly Plan</p>
    </div>
    <Button variant="outline">Cancel Subscription</Button>
  </div>
  
  <div className="flex items-center justify-between py-4 border-t border-gray-200">
    <div>
      <p className="text-gray-900">
        Your next payment is <span className="font-semibold">$59.00 USD</span>, to be charged on{" "}
        <span className="font-semibold">April 08, 2022</span>
      </p>
    </div>
    <div>
      <p className="text-gray-600 text-sm">Your payment will be automatically renewed each month</p>
    </div>
  </div>
</CardContent>
```

### Usage Guidance

Use consistent padding (p-6) and add vertical spacing between child content elements with margin-bottom (mb-4) for clear separation. Use border-t for separating sections within the card content.

---

## Sidebar Header

### Appearance Description

Sidebar header contains the branding or setup action. It uses prominent blue-600 color for buttons and a clean white background with border-r border-gray-200.

### Example Code

```html
<div className="p-6 border-b border-gray-200">
  <div className="flex items-center gap-2">
    <div className="w-8 h-8 bg-blue-600 rounded-full flex items-center justify-center">
      <div className="w-4 h-4 bg-white rounded-full"></div>
    </div>
    <span className="text-xl font-semibold text-gray-900">ClarityOI</span>
  </div>
</div>

<div className="p-4">
  <Button className="w-full bg-blue-600 hover:bg-blue-700 text-white">
    <Plus className="w-4 h-4 mr-2" />
    Connect New Account
  </Button>
</div>
```

### Usage Guidance

Use sidebar header for main sidebar actions or branding. Ensure button has sufficient hit area and stands out with strong background color. The logo should be simple and recognizable.

---

## Sidebar Item

### Appearance Description

Sidebar items are vertically stacked links with icon and text. They use text-gray-900 for active and text-gray-600 for inactive states, with left padding and hover background to highlight.

### Example Code

```html
<div className="flex items-center gap-3 px-3 py-2 text-gray-900 bg-gray-100 rounded-lg">
  <Home className="w-5 h-5" />
  <span className="font-medium">Dashboard</span>
</div>

<div className="flex items-center gap-3 px-3 py-2 text-gray-600 hover:text-gray-900 hover:bg-gray-50 rounded-lg cursor-pointer">
  <BarChart3 className="w-5 h-5" />
  <span>Performance</span>
</div>
```

### Usage Guidance

Use consistent padding (px-3 py-2) for click targets. Highlight active items with bg-gray-100 and text-gray-900. Inactive items should have text-gray-600 with hover:text-gray-900 and hover:bg-gray-50. Use gap-3 for spacing between icon and text.

---

## Sidebar Section

### Appearance Description

Sidebar sections group related navigation items with a header label in uppercase. Items within a section are stacked vertically with consistent spacing.

### Example Code

```html
<div className="space-y-1">
  <div className="px-3 py-1 text-xs font-medium text-gray-500 uppercase tracking-wider">ANALYTICS</div>
  <div className="flex items-center gap-3 px-3 py-2 text-gray-600 hover:text-gray-900 hover:bg-gray-50 rounded-lg cursor-pointer">
    <BarChart3 className="w-5 h-5" />
    <span>Performance</span>
  </div>
  <div className="flex items-center gap-3 px-3 py-2 text-gray-600 hover:text-gray-900 hover:bg-gray-50 rounded-lg cursor-pointer">
    <Target className="w-5 h-5" />
    <span>Hotjar</span>
    <Badge variant="secondary" className="ml-auto bg-blue-100 text-blue-800 text-xs">
      NEW
    </Badge>
  </div>
</div>
```

### Usage Guidance

Use uppercase text-xs font-medium text-gray-500 for section headers. Maintain consistent spacing between sections (mt-6) and items within sections (space-y-1). Badge indicators should be positioned with ml-auto.

---

## Header Navigation

### Appearance Description

Header navigation includes search, notification icons, and user profile elements aligned horizontally with subtle spacing and interactive states.

### Example Code

```html
<header className="bg-white border-b border-gray-200 px-6 py-4">
  <div className="flex items-center justify-between">
    <div className="flex items-center gap-4">
      <div className="relative">
        <Search className="w-5 h-5 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
        <input
          type="text"
          placeholder="Type to search"
          className="pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent w-80"
        />
      </div>
    </div>
    <div className="flex items-center gap-4">
      <Button variant="ghost" size="icon">
        <MessageSquare className="w-5 h-5" />
      </Button>
      <Button variant="ghost" size="icon">
        <Bell className="w-5 h-5" />
      </Button>
      <div className="w-8 h-8 bg-gray-300 rounded-full"></div>
    </div>
  </div>
</header>
```

### Usage Guidance

Position search input on the left with an icon inside. Use ghost buttons for notification icons. Keep consistent spacing (gap-4) between elements. Use rounded-full for user avatar.

---

## Dropdown Menu

### Appearance Description

Dropdown menus use the DropdownMenu component with trigger and content. They provide a clean interface for additional options.

### Example Code

```html
<DropdownMenu>
  <DropdownMenuTrigger asChild>
    <Button variant="ghost" size="sm">
      Sort by: Recent <ChevronDown className="w-4 h-4 ml-1" />
    </Button>
  </DropdownMenuTrigger>
  <DropdownMenuContent>
    <DropdownMenuItem>Recent</DropdownMenuItem>
    <DropdownMenuItem>Oldest</DropdownMenuItem>
    <DropdownMenuItem>Amount</DropdownMenuItem>
  </DropdownMenuContent>
</DropdownMenu>
```

### Usage Guidance

Use DropdownMenu components for consistent dropdown behavior. Trigger elements should indicate dropdown functionality (e.g., with ChevronDown icon). Menu items should have consistent styling and sufficient padding for clickable area.

---

## Avatar

### Appearance Description

Avatars are circular elements with fixed size, used for user profiles or placeholders.

### Example Code

```html
<div className="w-8 h-8 bg-gray-300 rounded-full"></div>
```

### Usage Guidance

Use consistent sizing (w-8 h-8 for header, potentially larger elsewhere). For image avatars, use object-cover to maintain aspect ratio. For placeholder avatars, use bg-gray-300 or similar neutral color.

---

## Icon

### Appearance Description

Icons are used throughout the UI, sized typically 20px by 20px (w-5 h-5), with text color classes to adapt color dynamically.

### Example Code

```html
<Home className="w-5 h-5" />
<Plus className="w-4 h-4 mr-2" />
<Bell className="w-5 h-5" />
```

### Usage Guidance

Use Lucide icons for consistency. Maintain standard sizes: w-5 h-5 for navigation and standalone icons, w-4 h-4 for icons within buttons or smaller contexts. Add appropriate margin (mr-2) when used alongside text.

---

## Table

### Appearance Description

Tables use the Table component with TableHeader, TableRow, TableHead, TableBody, and TableCell components for structured data display.

### Example Code

```html
<Table>
  <TableHeader>
    <TableRow>
      <TableHead>Invoice</TableHead>
      <TableHead>Date</TableHead>
      <TableHead>Amount</TableHead>
      <TableHead>Status</TableHead>
      <TableHead className="w-12"></TableHead>
    </TableRow>
  </TableHeader>
  <TableBody>
    <TableRow>
      <TableCell className="font-medium">Standard Plan - Feb 2022</TableCell>
      <TableCell>07 February, 2022</TableCell>
      <TableCell>$59.00</TableCell>
      <TableCell>
        <div className="flex items-center gap-2">
          <div className="w-2 h-2 bg-green-500 rounded-full"></div>
          <span className="text-green-700">Complete</span>
        </div>
      </TableCell>
      <TableCell>
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="icon">
              <MoreHorizontal className="w-4 h-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent>
            <DropdownMenuItem>Download</DropdownMenuItem>
            <DropdownMenuItem>View Details</DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </TableCell>
    </TableRow>
    <!-- More rows -->
  </TableBody>
</Table>
```

### Usage Guidance

Use the Table component family for consistent table styling. Use font-medium for primary column data. For status indicators, combine a colored dot (w-2 h-2 bg-green-500 rounded-full) with text. Add action buttons in the last column with appropriate dropdown menus.

---

## Input

### Appearance Description

Input fields have white backgrounds, subtle border with border-gray-300, rounded corners (rounded-lg), and focus states with ring-2 ring-blue-500. Search inputs often include an icon.

### Example Code

```html
<div className="relative">
  <Search className="w-5 h-5 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
  <input
    type="text"
    placeholder="Type to search"
    className="pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent w-80"
  />
</div>
```

### Usage Guidance

For search inputs, position the icon absolutely within the input. Use sufficient padding (py-2) for touch targets and typing comfort. Include placeholder text for guidance. Define appropriate width based on context (w-80 for search). Use focus:outline-none focus:ring-2 focus:ring-blue-500 for accessible focus states.

---

## Button

### Appearance Description

Buttons use the Button component with various variants (default, outline, ghost) and sizes. They can include icons and text.

### Example Code

```html
<!-- Primary Button -->
<Button className="w-full bg-blue-600 hover:bg-blue-700 text-white">
  <Plus className="w-4 h-4 mr-2" />
  Connect New Account
</Button>

<!-- Outline Button -->
<Button variant="outline">Cancel Subscription</Button>

<!-- Ghost Button -->
<Button variant="ghost" size="sm">
  Sort by: Recent <ChevronDown className="w-4 h-4 ml-1" />
</Button>

<!-- Icon Button -->
<Button variant="ghost" size="icon">
  <MessageSquare className="w-5 h-5" />
</Button>
```

### Usage Guidance

Use primary buttons (bg-blue-600) for main actions. Use outline buttons for secondary actions. Use ghost buttons for tertiary actions or in compact spaces. Include icons where appropriate to enhance meaning. Size appropriately (default, sm, icon) based on context and available space.

## Tabs

### Appearance Description

Tabs use the Tabs component family to organize content into different sections that can be switched between.

### Example Code

```html
<Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
  <TabsList className="grid w-full grid-cols-6 bg-gray-100">
    <TabsTrigger value="profile">Profile</TabsTrigger>
    <TabsTrigger value="password">Password</TabsTrigger>
    <TabsTrigger value="team">Team</TabsTrigger>
    <TabsTrigger value="notification">Notification</TabsTrigger>
    <TabsTrigger value="billing-details">Billing Details</TabsTrigger>
    <TabsTrigger value="integration">Integration</TabsTrigger>
  </TabsList>

  <TabsContent value="billing-details" className="space-y-6">
    <!-- Content for this tab -->
  </TabsContent>
  
  <TabsContent value="profile">
    <!-- Content for this tab -->
  </TabsContent>
  
  <!-- Other tab contents -->
</Tabs>
```

### Usage Guidance

Use Tabs for organizing related content that doesn't need to be visible simultaneously. TabsList should use appropriate styling (bg-gray-100) and layout (grid grid-cols-6). Each TabsContent should maintain consistent spacing (space-y-6) for content sections.

## Badge

### Appearance Description

Badges are small indicators used to highlight status, counts, or labels.

### Example Code

```html
<Badge variant="secondary" className="ml-auto bg-blue-100 text-blue-800 text-xs">
  NEW
</Badge>

<Badge variant="secondary" className="ml-auto bg-gray-200 text-gray-700 text-xs">
  15
</Badge>
```

### Usage Guidance

Use badges sparingly to highlight important information. Position with ml-auto when used in navigation items. Use appropriate color combinations for different states (blue for new features, gray for counts, etc.). Keep text concise and uppercase for emphasis.
