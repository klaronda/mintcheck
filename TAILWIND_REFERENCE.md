# Tailwind CSS v4 Reference - MintCheck Project

## Quick Reference for Cursor AI

This document provides all Tailwind classes and custom CSS used in the MintCheck project for easy autocomplete and reference.

## Design Tokens (CSS Variables)

### Color Variables
```css
/* Available as Tailwind classes: bg-primary, text-primary, border-primary, etc. */
--primary: #3EB489              /* bg-primary, text-primary */
--primary-foreground: #ffffff   /* text-primary-foreground */
--background: #ffffff            /* bg-background */
--foreground: #1a1a1a           /* text-foreground */
--secondary: #f5f5f5            /* bg-secondary */
--secondary-foreground: #1a1a1a /* text-secondary-foreground */
--muted: #f5f5f5                /* bg-muted */
--muted-foreground: #666666     /* text-muted-foreground */
--accent: #e8f5f0               /* bg-accent */
--accent-foreground: #1a1a1a    /* text-accent-foreground */
--destructive: #d4183d          /* bg-destructive */
--destructive-foreground: #ffffff /* text-destructive-foreground */
--border: #e5e5e5               /* border-border */
--input-background: #f5f5f5     /* bg-input-background */
--ring: #3EB489                 /* ring-ring */
```

### Spacing & Layout
```css
--radius: 0.5rem                /* rounded-lg */
--radius-sm: calc(var(--radius) - 4px)  /* rounded-sm */
--radius-md: calc(var(--radius) - 2px)  /* rounded-md */
--radius-xl: calc(var(--radius) + 4px)  /* rounded-xl */
```

## Common Component Patterns

### Containers & Sections
```html
<!-- Standard content container -->
<div class="max-w-4xl mx-auto px-6 py-24">

<!-- Wide container -->
<div class="max-w-6xl mx-auto px-6 py-24">

<!-- Extra wide container -->
<div class="max-w-7xl mx-auto px-6 py-24">

<!-- Section with border -->
<section class="border-b border-border">

<!-- Section with alternate background -->
<section style="backgroundColor: '#FCFCFB'">
<section style="backgroundColor: '#F8F8F7'">
```

### Buttons
```html
<!-- Primary button -->
<button class="bg-primary text-primary-foreground px-8 py-4 rounded-lg hover:opacity-90 transition-opacity">

<!-- Primary button with icon -->
<button class="inline-flex items-center gap-2 bg-primary text-primary-foreground px-8 py-4 rounded-lg hover:opacity-90 transition-opacity">
  <Icon class="w-5 h-5" />
  Button Text
</button>

<!-- Secondary button -->
<button class="border border-border px-6 py-3 rounded-lg hover:bg-gray-50 transition-colors">

<!-- Small button -->
<button class="px-4 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-[#359e7a] transition-colors text-sm">

<!-- Ghost button -->
<button class="p-2 hover:bg-gray-100 rounded transition-colors">

<!-- Link button -->
<button class="text-muted-foreground hover:text-foreground transition-colors">
```

### Cards
```html
<!-- Standard card -->
<div class="bg-white border border-border rounded-lg p-6">

<!-- Card with hover -->
<div class="bg-white border border-border rounded-lg p-6 hover:shadow-lg transition-shadow">

<!-- Product card -->
<div class="bg-white border border-border rounded-lg overflow-hidden">
  <div class="aspect-square bg-secondary/50 p-6">...</div>
  <div class="p-5 space-y-3">...</div>
</div>

<!-- Icon card -->
<div class="bg-white border border-border rounded-lg p-8 space-y-4">
  <div class="w-12 h-12 bg-primary rounded-full flex items-center justify-center">
    <Icon class="w-6 h-6 text-white" />
  </div>
  <h3>Title</h3>
  <p>Description</p>
</div>
```

### Typography
```html
<!-- Hero heading -->
<h1 class="text-4xl md:text-5xl tracking-tight" style="fontWeight: 600">

<!-- Section heading -->
<h2 class="text-3xl text-center mb-16" style="fontWeight: 600">

<!-- Subsection heading -->
<h3 class="text-2xl" style="fontWeight: 600">

<!-- Small heading -->
<h3 class="text-xl" style="fontWeight: 600">

<!-- Body text -->
<p class="text-muted-foreground leading-relaxed">

<!-- Large body text -->
<p class="text-xl text-muted-foreground leading-relaxed">

<!-- Small text -->
<p class="text-sm text-muted-foreground">

<!-- Badge/label -->
<span class="text-xs px-2 py-1 bg-gray-100 rounded">
```

### Grid Layouts
```html
<!-- Two columns -->
<div class="grid md:grid-cols-2 gap-12">

<!-- Three columns -->
<div class="grid md:grid-cols-3 gap-12">

<!-- 1/3 + 2/3 split -->
<div class="grid md:grid-cols-3 gap-12">
  <div class="md:col-span-1">...</div>
  <div class="md:col-span-2">...</div>
</div>

<!-- Auto-fit responsive -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
```

### Flexbox Layouts
```html
<!-- Centered content -->
<div class="flex items-center justify-center">

<!-- Space between -->
<div class="flex justify-between items-center">

<!-- Vertical stack with gap -->
<div class="flex flex-col gap-4">

<!-- Horizontal row with gap -->
<div class="flex items-center gap-2">

<!-- Wrap -->
<div class="flex flex-wrap gap-4">
```

### Images
```html
<!-- Standard rounded image -->
<img class="w-full h-full object-cover rounded-lg" />

<!-- Square aspect ratio -->
<img class="w-full aspect-square object-cover rounded-lg" />

<!-- With max-width -->
<img class="w-full max-w-sm rounded-lg shadow-lg" />

<!-- Image container with aspect -->
<div class="aspect-video bg-secondary/50 rounded-lg overflow-hidden">
  <img class="w-full h-full object-cover" />
</div>
```

### Forms & Inputs
```html
<!-- Text input -->
<input 
  type="text"
  class="w-full px-4 py-2 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
/>

<!-- Textarea -->
<textarea 
  class="w-full px-4 py-2 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
  rows="3"
/>

<!-- Select -->
<select class="w-full px-4 py-2 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary">
  <option>Option</option>
</select>

<!-- Checkbox -->
<input type="checkbox" class="w-4 h-4" />

<!-- Label -->
<label class="block text-sm mb-2" style="fontWeight: 600">
```

### Spacing Utilities

#### Padding
```
p-2    /* 0.5rem */
p-3    /* 0.75rem */
p-4    /* 1rem */
p-5    /* 1.25rem */
p-6    /* 1.5rem */
p-8    /* 2rem */

px-4 py-2  /* Common button padding */
px-6 py-3  /* Medium button */
px-8 py-4  /* Large button */
px-6 py-24 /* Section padding */
```

#### Margin
```
m-auto     /* Auto centering */
mx-auto    /* Horizontal auto */
mb-2 mb-4 mb-6 mb-8 mb-12 mb-16  /* Bottom margin */
mt-6       /* Top margin */
```

#### Gap
```
gap-2 gap-3 gap-4 gap-6 gap-8 gap-12  /* Flexbox/Grid gap */
space-y-4 space-y-6 space-y-8 space-y-12  /* Vertical spacing */
```

### Borders & Shadows
```html
<!-- Border -->
<div class="border border-border">
<div class="border-b border-border">   /* Bottom only */
<div class="border-t border-border">   /* Top only */

<!-- Rounded corners -->
<div class="rounded">      /* 0.25rem */
<div class="rounded-lg">   /* 0.5rem */
<div class="rounded-xl">   /* 0.75rem */
<div class="rounded-full"> /* Fully rounded */

<!-- Shadows -->
<div class="shadow-lg">
<div class="shadow-sm">
```

### Colors & Backgrounds
```html
<!-- Brand colors -->
<div class="bg-primary text-primary-foreground">
<div class="bg-[#3EB489] text-white">  /* Direct hex */
<div class="bg-[#359e7a]">             /* Hover shade */

<!-- Neutral colors -->
<div class="bg-white">
<div class="bg-gray-50">
<div class="bg-gray-100">
<div class="bg-secondary">

<!-- Text colors -->
<div class="text-foreground">
<div class="text-muted-foreground">
<div class="text-white">

<!-- Background opacity -->
<div class="bg-secondary/50">  /* 50% opacity */
<div class="bg-primary/10">    /* 10% opacity */
```

### Transitions & Animations
```html
<!-- Opacity transition -->
<div class="hover:opacity-90 transition-opacity">

<!-- Color transition -->
<div class="hover:bg-gray-50 transition-colors">

<!-- Multiple transitions -->
<div class="hover:shadow-lg transition-shadow">

<!-- Custom hover -->
<div class="hover:text-foreground transition-colors">
```

### Positioning
```html
<!-- Relative/Absolute -->
<div class="relative">
<div class="absolute top-0 right-0">

<!-- Sticky -->
<div class="sticky top-0">

<!-- Fixed -->
<div class="fixed bottom-4 right-4">

<!-- Z-index -->
<div class="z-10">
<div class="z-50">
```

### Responsive Breakpoints
```
sm:  /* 640px */
md:  /* 768px */
lg:  /* 1024px */
xl:  /* 1280px */
2xl: /* 1536px */

<!-- Examples -->
<div class="text-xl md:text-2xl lg:text-3xl">
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
<div class="px-4 md:px-6 lg:px-8">
<div class="py-16 md:py-24">
```

### Common Class Combinations

#### Section Header
```html
<div class="text-center space-y-4 mb-12">
  <h2 class="text-3xl" style="fontWeight: 600">Section Title</h2>
  <p class="text-lg text-muted-foreground leading-relaxed max-w-2xl mx-auto">
    Section description
  </p>
</div>
```

#### Icon Container
```html
<div class="w-12 h-12 bg-accent rounded-lg flex items-center justify-center">
  <Icon class="w-6 h-6 text-primary" />
</div>
```

#### Badge
```html
<span class="text-xs px-2 py-1 bg-gray-100 rounded">Label</span>
<span class="text-xs px-2 py-1 bg-primary/10 text-primary rounded">Active</span>
<span class="text-xs px-2 py-1 bg-red-100 text-red-700 rounded">Draft</span>
```

#### Article List Item
```html
<div class="bg-white rounded-lg border border-border p-6 flex gap-6">
  <img class="w-32 h-32 object-cover rounded-lg flex-shrink-0" />
  <div class="flex-1 min-w-0">
    <h3 class="text-lg mb-1" style="fontWeight: 600">Title</h3>
    <p class="text-sm text-muted-foreground">Description</p>
  </div>
</div>
```

#### Navigation Link
```html
<a href="#section" class="text-foreground hover:text-primary transition-colors">
  Link Text
</a>
```

## Admin Dashboard Specific

### Form Layouts
```html
<!-- Form row -->
<div class="grid grid-cols-2 gap-4">

<!-- Form section -->
<div class="space-y-4 pb-6 border-b border-border">
  <h3 style="fontWeight: 600">Section Title</h3>
  ...
</div>

<!-- Scrollable form -->
<form class="space-y-6 max-h-[70vh] overflow-y-auto pr-4">
```

### Filter Tabs
```html
<button class="px-4 py-2 rounded-lg bg-primary text-white">  /* Active */
<button class="px-4 py-2 rounded-lg border border-border hover:bg-gray-50">  /* Inactive */
```

### Action Buttons
```html
<!-- Icon buttons -->
<button class="p-2 hover:bg-gray-100 rounded transition-colors">
  <Icon class="w-4 h-4" />
</button>

<!-- Delete button -->
<button class="p-2 hover:bg-red-50 text-red-600 rounded transition-colors">
  <Trash2 class="w-4 h-4" />
</button>
```

## Utility Classes

### Display
```
hidden
block
inline-block
flex
inline-flex
grid
```

### Overflow
```
overflow-hidden
overflow-y-auto
overflow-x-scroll
```

### Width/Height
```
w-full
w-32 w-48 w-64
h-full
h-48 h-64
max-w-xs max-w-sm max-w-md max-w-lg max-w-xl max-w-2xl max-w-4xl max-w-6xl max-w-7xl
min-h-screen
```

### Flexbox/Grid Alignment
```
items-start items-center items-end
justify-start justify-center justify-end justify-between
flex-col flex-row
flex-shrink-0 flex-1
```

### Misc
```
cursor-pointer
pointer-events-none
select-none
aspect-square aspect-video
object-cover object-contain
tracking-tight
leading-relaxed
```

## Custom Inline Styles

Due to Tailwind v4 base layer overrides, font-weight is often set inline:

```html
<h1 style="fontWeight: 600">Title</h1>
<button style="fontWeight: 600">Button</button>
```

Background colors for specific shades:
```html
<section style="backgroundColor: '#FCFCFB'">  /* Off-white */
<section style="backgroundColor: '#F8F8F7'">  /* Light gray */
```

## Icon Sizing (Lucide React)
```html
<Icon class="w-3 h-3" />     /* Extra small (12px) */
<Icon class="w-3.5 h-3.5" /> /* Small (14px) */
<Icon class="w-4 h-4" />     /* Regular (16px) */
<Icon class="w-5 h-5" />     /* Medium (20px) */
<Icon class="w-6 h-6" />     /* Large (24px) */
```

## Dark Mode Support

Classes automatically support dark mode via `.dark` parent class:
```html
<div class="bg-white dark:bg-gray-900 text-foreground dark:text-white">
```

However, MintCheck currently uses light mode only.

---

**Note**: This reference is based on Tailwind CSS v4.1.12. All custom classes are defined in `/src/styles/theme.css`.
