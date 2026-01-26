# MintCheck - Cursor IDE Setup Guide

## Project Overview
MintCheck is a single-page marketing website for an iOS app that helps people make smarter decisions when buying or owning used cars through OBD-II scanner diagnostics.

## Tech Stack
- **Framework**: React 18.3.1
- **Build Tool**: Vite 6.3.5
- **Styling**: Tailwind CSS v4.1.12
- **Routing**: React Router 7.12.0
- **SEO**: react-helmet-async
- **UI Components**: Radix UI primitives + custom components
- **Icons**: Lucide React
- **Animation**: Motion (formerly Framer Motion)

## Project Structure

```
/src
  /app
    /components
      /ui              # Radix UI components (shadcn-style)
      /figma           # Protected Figma components
      Footer.tsx       # Site footer with easter egg
      Layout.tsx       # Main layout wrapper
      Navbar.tsx       # Navigation bar
      RichTextEditor.tsx # CMS rich text editor
      ScrollToTop.tsx  # Scroll restoration
    /contexts
      AdminContext.tsx # CMS admin state management
    /pages
      Home.tsx         # Main landing page
      Blog.tsx         # Blog listing with hero
      BlogArticle.tsx  # Individual blog post
      Support.tsx      # Support center
      SupportArticle.tsx # Individual support article
      PrivacyPolicy.tsx
      TermsOfUse.tsx
      AdminLogin.tsx   # CMS login (admin@mintcheckapp.com / mintcheck2024)
      AdminDashboard.tsx # CMS dashboard
    routes.ts          # React Router configuration
    App.tsx            # Root component
  /styles
    index.css          # Main CSS entry point
    tailwind.css       # Tailwind v4 imports
    theme.css          # Design tokens & theme
    fonts.css          # Font imports (if exists)
```

## Vite Configuration

**File**: `/vite.config.ts`

```typescript
import { defineConfig } from 'vite'
import path from 'path'
import tailwindcss from '@tailwindcss/vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [
    react(),
    tailwindcss(),
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
})
```

**Key Points**:
- Uses `@` alias for absolute imports from `/src`
- Example: `import { Navbar } from '@/app/components/Navbar'`
- Tailwind CSS v4 plugin is required

## Tailwind CSS v4 Setup

### Main CSS Entry (`/src/styles/index.css`)
```css
@import './fonts.css';
@import './tailwind.css';
@import './theme.css';
```

### Tailwind Configuration (`/src/styles/tailwind.css`)
```css
@import 'tailwindcss' source(none);
@source '../**/*.{js,ts,jsx,tsx}';

@import 'tw-animate-css';
```

### Design Tokens (`/src/styles/theme.css`)

#### Brand Colors
- **Primary (Mint Green)**: `#3EB489` - Main brand color
- **Background**: `#ffffff` (light) / `oklch(0.145 0 0)` (dark)
- **Foreground**: `#1a1a1a` (light) / `oklch(0.985 0 0)` (dark)
- **Secondary**: `#f5f5f5` - Light gray backgrounds
- **Muted Foreground**: `#666666` - Secondary text
- **Accent**: `#e8f5f0` - Mint green tint for backgrounds
- **Border**: `#e5e5e5` - Subtle borders
- **Destructive**: `#d4183d` - Error/delete actions

#### CSS Custom Properties
```css
:root {
  --primary: #3EB489;
  --primary-foreground: #ffffff;
  --background: #ffffff;
  --foreground: #1a1a1a;
  --secondary: #f5f5f5;
  --muted-foreground: #666666;
  --accent: #e8f5f0;
  --border: #e5e5e5;
  --radius: 0.5rem;
}
```

#### Typography Defaults
- **Font Stack**: System fonts (default browser)
- **Base Size**: 16px
- **Headings**: `font-weight: 600` (semibold)
- **Body**: `font-weight: 400` (normal)

#### Common Tailwind Classes Used
- **Colors**: `bg-primary`, `text-primary`, `text-muted-foreground`
- **Spacing**: `px-6`, `py-24`, `gap-12`, `space-y-6`
- **Layout**: `max-w-6xl`, `mx-auto`, `grid md:grid-cols-2`
- **Borders**: `border`, `border-border`, `rounded-lg`
- **Typography**: Inline `style={{ fontWeight: 600 }}` (overrides base styles)

## PostCSS Configuration

**File**: `/postcss.config.mjs`

```javascript
export default {}
```

No additional PostCSS plugins needed - Tailwind v4 handles everything automatically.

## Package Management

**Manager**: pnpm (preferred, but npm/yarn work)

**Key Dependencies**:
```json
{
  "react": "18.3.1",
  "react-dom": "18.3.1",
  "react-router": "7.12.0",
  "react-helmet-async": "2.0.5",
  "lucide-react": "0.487.0",
  "motion": "12.23.24",
  "tailwindcss": "4.1.12",
  "@tailwindcss/vite": "4.1.12"
}
```

**Install Command**:
```bash
pnpm install
# or
npm install
```

**Build Command**:
```bash
npm run build
```

## Routing Configuration

Uses React Router's Data mode with `createBrowserRouter`:

```typescript
import { createBrowserRouter } from 'react-router';

export const router = createBrowserRouter([
  {
    Component: Layout,
    children: [
      { path: '/', Component: Home },
      { path: '/privacy', Component: PrivacyPolicy },
      { path: '/terms', Component: TermsOfUse },
      { path: '/support', Component: Support },
      { path: '/support/:slug', Component: SupportArticle },
      { path: '/blog', Component: Blog },
      { path: '/blog/:slug', Component: BlogArticle },
      { path: '/admin/login', Component: AdminLogin },
      { path: '/admin', Component: AdminDashboard },
    ],
  },
]);
```

## Design System Guidelines

### Layout Patterns
- **Container**: `max-w-4xl mx-auto px-6` (content) or `max-w-6xl` (wider)
- **Section Padding**: `py-24` (desktop), `py-16` (mobile)
- **Section Borders**: `border-b border-border`
- **Alternating Backgrounds**: `bg-white` and `style={{ backgroundColor: '#FCFCFB' }}`

### Component Patterns
- **Buttons**: `bg-primary text-primary-foreground px-8 py-4 rounded-lg`
- **Icons**: From `lucide-react`, typically `w-5 h-5` or `w-6 h-6`
- **Cards**: `bg-white border border-border rounded-lg p-6`
- **Images**: `rounded-lg object-cover` with appropriate aspect ratios

### Typography Patterns
- **Hero Heading**: `text-4xl md:text-5xl` with `font-weight: 600`
- **Section Heading**: `text-3xl` with `font-weight: 600`
- **Subsection Heading**: `text-2xl` with `font-weight: 600`
- **Body Text**: `text-muted-foreground leading-relaxed`
- **Large Body**: `text-xl text-muted-foreground leading-relaxed`

### Responsive Grid Patterns
```html
<!-- Two-column layout -->
<div class="grid md:grid-cols-2 gap-12">

<!-- Three-column layout -->
<div class="grid md:grid-cols-3 gap-12">

<!-- Asymmetric layout (1/3 + 2/3) -->
<div class="grid md:grid-cols-3 gap-12">
  <div class="md:col-span-1">...</div>
  <div class="md:col-span-2">...</div>
</div>
```

## CMS System

### Admin Access
- **URL**: `/admin`
- **Login**: `admin@mintcheckapp.com` / `mintcheck2024`
- **Easter Egg**: Triple-click "© 2026" in footer for hidden access

### Features
- Rich text editor with image upload support
- Support for 50+ articles (support + blog)
- Three support categories: Device Help, Using the App, Vehicle Support
- Blog posts display in reverse chronological order
- Hero image upload (base64 or URL)
- Draft/publish toggle
- Article management (create, edit, delete)

### Admin Context
State managed via `AdminContext.tsx` with localStorage persistence:
```typescript
{
  articles: Article[],
  addArticle: (data) => void,
  updateArticle: (id, updates) => void,
  deleteArticle: (id) => void,
}
```

## SEO Configuration

Every page includes comprehensive meta tags via `react-helmet-async`:

```tsx
<Helmet>
  <title>Page Title | MintCheck</title>
  <meta name="description" content="..." />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <link rel="canonical" href="https://mintcheckapp.com/path" />
  
  {/* Open Graph */}
  <meta property="og:title" content="..." />
  <meta property="og:description" content="..." />
  <meta property="og:type" content="website" />
  <meta property="og:url" content="..." />
  
  {/* Twitter Card */}
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:title" content="..." />
  <meta name="twitter:description" content="..." />
</Helmet>
```

## Protected Files

**DO NOT MODIFY**:
- `/src/app/components/figma/ImageWithFallback.tsx`
- `/pnpm-lock.yaml`

## Import Guidelines

### Absolute Imports (Preferred)
```tsx
import { Navbar } from '@/app/components/Navbar';
import { useAdmin } from '@/app/contexts/AdminContext';
```

### External Packages
```tsx
import { Apple, Plug, Scan } from 'lucide-react';
import { Link } from 'react-router';
import { Helmet } from 'react-helmet-async';
```

### Images
- Use Unsplash URLs for photos
- Local images use `figma:asset/...` scheme (virtual module)
- SVGs imported from `/src/imports/` directory

## Key Features

### Homepage Sections
1. **Hero** - Main value proposition with iOS app CTA
2. **How It Works** - 3-step process (Plug, Scan, Get Guidance)
3. **Use Cases** - Buying vs Owning scenarios
4. **OBD-II Scanners** - 3 product cards with Amazon links
5. **Trust & Boundaries** - What MintCheck does/doesn't do
6. **About** - Founder story with image

### Navigation
- Logo lockup (left)
- Anchor links: How It Works, Use Cases, About
- Mobile hamburger menu
- Smooth scroll behavior

### Footer
- Four columns: Company, Legal, Support, Resources
- Social media links (placeholder)
- Copyright with easter egg (triple-click "© 2026")
- Email: support@mintcheckapp.com

## Development Workflow

### Starting Development
```bash
# Install dependencies
pnpm install

# Start dev server (handled by Figma Make)
# Build for production
npm run build
```

### Common Tasks
- **Add new page**: Create in `/src/app/pages/`, add to `routes.ts`
- **Add new component**: Create in `/src/app/components/`
- **Modify styles**: Edit `/src/styles/theme.css` for design tokens
- **Update CMS**: Login at `/admin`, use rich text editor
- **SEO updates**: Edit `<Helmet>` tags in page components

### Cursor AI Tips
- Use `@` alias for all local imports
- Reference `/src/styles/theme.css` for color variables
- Tailwind v4 uses CSS custom properties, not `tailwind.config.js`
- Follow existing component patterns in `/src/app/components/ui/`
- Use Lucide React for icons (already installed)

## Brand Voice & Content
- **Reading Level**: 10th grade (simple, clear language)
- **Tone**: Calm, professional, helpful
- **Aesthetic**: Generous whitespace, subtle borders, no gradients
- **Color Palette**: Mint green accent, neutral grays, white backgrounds
- **No**: Illustrations, gimmicky UI, technical jargon

## Testing Checklist
- [ ] All links work (including external Amazon links)
- [ ] Responsive on mobile/tablet/desktop
- [ ] SEO meta tags present on all pages
- [ ] Admin CMS login works
- [ ] Blog/support articles display correctly
- [ ] Footer easter egg (triple-click) works
- [ ] Navigation smooth scrolls to sections
- [ ] Images load properly
- [ ] Lighthouse scores: Performance, Accessibility, Best Practices, SEO

## Environment Variables
None required - no API keys, all content in localStorage.

## Browser Support
- Modern browsers (Chrome, Firefox, Safari, Edge)
- ES2020+ JavaScript
- CSS Grid & Flexbox

---

**Last Updated**: 2026-01-23
**Version**: 1.0.0
**Maintainer**: MintCheck Team
