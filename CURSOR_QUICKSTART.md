# Cursor AI - Quick Start Guide for MintCheck

This guide helps Cursor AI understand the MintCheck project structure and coding patterns instantly.

## 🚀 Project Type
**Single-page marketing website** for MintCheck iOS app (OBD-II car diagnostics)

## 🛠️ Stack at a Glance
- **React 18.3.1** + **Vite 6.3.5**
- **Tailwind CSS v4** (NO tailwind.config.js - uses theme.css)
- **React Router 7** (Data mode)
- **TypeScript** enabled

## 📁 Key Files for Context

### Must-Read Files
1. `/CURSOR_SETUP.md` - Full project documentation
2. `/TAILWIND_REFERENCE.md` - All Tailwind classes used
3. `/COMPONENT_LIBRARY.md` - All components and APIs
4. `/src/styles/theme.css` - Design tokens and colors
5. `/src/app/routes.ts` - All routes
6. `/vite.config.ts` - Build configuration

### Entry Points
- **Main App**: `/src/app/App.tsx`
- **Homepage**: `/src/app/pages/Home.tsx`
- **Routes**: `/src/app/routes.ts`
- **Styles**: `/src/styles/index.css`

## 🎨 Design System Cheat Sheet

### Brand Colors (Use These!)
```tsx
// Primary (Mint Green)
className="bg-primary text-primary-foreground"   // #3EB489
className="bg-[#3EB489] text-white"

// Hover shade
className="hover:bg-[#359e7a]"

// Neutral backgrounds
className="bg-white"                    // White
style={{ backgroundColor: '#FCFCFB' }} // Off-white
style={{ backgroundColor: '#F8F8F7' }} // Light gray

// Text colors
className="text-foreground"             // #1a1a1a (black)
className="text-muted-foreground"       // #666666 (gray)

// Borders
className="border border-border"        // #e5e5e5
```

### Typography Patterns
```tsx
// Always use inline styles for font-weight (overrides base layer)
<h1 className="text-4xl md:text-5xl" style={{ fontWeight: 600 }}>
<h2 className="text-3xl" style={{ fontWeight: 600 }}>
<h3 className="text-2xl" style={{ fontWeight: 600 }}>
<p className="text-muted-foreground leading-relaxed">
```

### Layout Patterns
```tsx
// Section container
<div className="max-w-4xl mx-auto px-6 py-24">

// Section border
<section className="border-b border-border">

// Two-column grid
<div className="grid md:grid-cols-2 gap-12">

// Three-column grid
<div className="grid md:grid-cols-3 gap-12">
```

### Button Patterns
```tsx
// Primary button
<button className="bg-primary text-primary-foreground px-8 py-4 rounded-lg hover:opacity-90 transition-opacity">

// Primary with icon
<button className="inline-flex items-center gap-2 bg-primary text-primary-foreground px-8 py-4 rounded-lg hover:opacity-90 transition-opacity">
  <Apple className="w-5 h-5" />
  Get the iOS App
</button>

// Secondary
<button className="border border-border px-6 py-3 rounded-lg hover:bg-gray-50 transition-colors">
```

### Card Patterns
```tsx
// Standard card
<div className="bg-white border border-border rounded-lg p-6">

// Icon card
<div className="bg-white border border-border rounded-lg p-8 space-y-4">
  <div className="w-12 h-12 bg-accent rounded-lg flex items-center justify-center">
    <Icon className="w-6 h-6 text-primary" />
  </div>
  <h3 style={{ fontWeight: 600 }}>Title</h3>
  <p className="text-muted-foreground leading-relaxed">Description</p>
</div>
```

## 📦 Import Patterns

### Always Use `@` Alias
```tsx
✅ import { Navbar } from '@/app/components/Navbar';
✅ import { useAdmin } from '@/app/contexts/AdminContext';
✅ import { Home } from '@/app/pages/Home';

❌ import { Navbar } from '../components/Navbar';
❌ import { useAdmin } from '../../contexts/AdminContext';
```

### External Packages
```tsx
import { Apple, Scan, Check } from 'lucide-react';
import { Link } from 'react-router';
import { Helmet } from 'react-helmet-async';
import { motion } from 'motion/react';
```

## 🧩 Common Components to Use

### Navigation & Layout
```tsx
import Navbar from '@/app/components/Navbar';
import Footer from '@/app/components/Footer';
```

### Admin/CMS
```tsx
import { useAdmin } from '@/app/contexts/AdminContext';
import RichTextEditor from '@/app/components/RichTextEditor';
```

### SEO (Every Page Needs This!)
```tsx
import { Helmet } from 'react-helmet-async';

<Helmet>
  <title>Page Title | MintCheck</title>
  <meta name="description" content="..." />
  <link rel="canonical" href="https://mintcheckapp.com/path" />
  <meta property="og:title" content="..." />
  <meta name="twitter:card" content="summary_large_image" />
</Helmet>
```

## 🎯 Quick Tasks

### Add a New Page
```tsx
// 1. Create file: /src/app/pages/NewPage.tsx
import { Helmet } from 'react-helmet-async';
import Navbar from '@/app/components/Navbar';
import Footer from '@/app/components/Footer';

export default function NewPage() {
  return (
    <div className="min-h-screen bg-white">
      <Helmet>
        <title>New Page | MintCheck</title>
        <meta name="description" content="..." />
      </Helmet>
      <Navbar />
      <main>
        <section className="max-w-4xl mx-auto px-6 py-24">
          <h1 className="text-4xl mb-6" style={{ fontWeight: 600 }}>
            Page Title
          </h1>
          <p className="text-muted-foreground leading-relaxed">
            Content goes here
          </p>
        </section>
      </main>
      <Footer />
    </div>
  );
}

// 2. Add to routes.ts
import NewPage from './pages/NewPage';

children: [
  { path: '/new-page', Component: NewPage },
]
```

### Add a New Component
```tsx
// /src/app/components/NewComponent.tsx
interface NewComponentProps {
  title: string;
  description?: string;
}

export default function NewComponent({ title, description }: NewComponentProps) {
  return (
    <div className="bg-white border border-border rounded-lg p-6">
      <h3 className="text-xl mb-2" style={{ fontWeight: 600 }}>
        {title}
      </h3>
      {description && (
        <p className="text-muted-foreground">{description}</p>
      )}
    </div>
  );
}
```

### Modify Styles
```tsx
// Option 1: Use existing Tailwind classes (preferred)
<div className="bg-primary text-white px-6 py-4 rounded-lg">

// Option 2: Add to theme.css for reusable tokens
// /src/styles/theme.css
:root {
  --new-color: #hexvalue;
}

@theme inline {
  --color-new-name: var(--new-color);
}

// Then use as:
<div className="bg-new-name">
```

### Access CMS Data
```tsx
import { useAdmin } from '@/app/contexts/AdminContext';

const { articles, addArticle, updateArticle, deleteArticle } = useAdmin();

// Get all blog posts
const blogPosts = articles.filter(a => a.type === 'blog' && a.published);

// Get support articles by category
const deviceHelp = articles.filter(a => 
  a.type === 'support' && 
  a.category === 'Device Help' && 
  a.published
);
```

## 🚨 Important Rules

### DO ✅
- Use `@` alias for all imports
- Add `<Helmet>` to every page
- Use inline `style={{ fontWeight: 600 }}` for headings
- Make everything responsive (`md:`, `lg:` breakpoints)
- Use Lucide React for icons
- Follow existing component patterns
- Test on mobile viewport

### DON'T ❌
- Create `tailwind.config.js` (Tailwind v4 uses CSS only)
- Modify `/src/app/components/figma/ImageWithFallback.tsx`
- Use relative imports (`../`, `../../`)
- Use Tailwind font classes without checking base styles first
- Forget SEO meta tags
- Use hardcoded colors (use design tokens)

## 🎨 Responsive Breakpoints
```tsx
sm:   640px
md:   768px   // Main breakpoint (mobile → desktop)
lg:   1024px
xl:   1280px
2xl:  1536px

// Example
<div className="px-4 md:px-6 lg:px-8">
<h1 className="text-3xl md:text-4xl lg:text-5xl">
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
```

## 📝 Content Guidelines

### Brand Voice
- **Reading Level**: 10th grade (simple, clear)
- **Tone**: Calm, professional, helpful
- **No**: Technical jargon, illustrations, gimmicky UI

### Copy Examples
```tsx
// Good ✅
"Make smarter decisions about used cars"
"Know what you're buying — or what your car needs — in plain English"

// Bad ❌
"Leverage advanced OBD-II diagnostic protocols"
"Utilize our proprietary algorithmic analysis"
```

## 🔑 CMS Access

### Login Credentials
```
URL: /admin/login (or triple-click "© 2026" in footer)
Email: admin@mintcheckapp.com
Password: mintcheck2024
```

### Article Management
- Up to 50 articles (support + blog)
- Rich text editor with formatting
- Hero image upload (URL or base64)
- Draft/publish toggle
- Auto-generated slugs

## 📚 Documentation Files

Reference these for detailed information:

1. **CURSOR_SETUP.md** - Complete project setup and configuration
2. **TAILWIND_REFERENCE.md** - All Tailwind classes and patterns
3. **COMPONENT_LIBRARY.md** - All components, props, and usage
4. **/src/styles/theme.css** - All design tokens and CSS variables

## 🐛 Common Issues

### Issue: Imports not working
**Solution**: Use `@` alias instead of relative paths
```tsx
✅ import { X } from '@/app/components/Component';
❌ import { X } from '../components/Component';
```

### Issue: Font-weight not applying
**Solution**: Use inline styles (Tailwind base layer overrides)
```tsx
✅ <h1 style={{ fontWeight: 600 }}>Title</h1>
❌ <h1 className="font-semibold">Title</h1>
```

### Issue: Custom color not working
**Solution**: Use direct hex for one-offs, or add to theme.css
```tsx
✅ className="bg-[#3EB489]"
✅ className="bg-primary"
❌ className="bg-mint-green"
```

### Issue: Dark mode not working
**Solution**: MintCheck uses light mode only (no dark mode support currently)

## 🏗️ Project Architecture

```
/src
  /app
    App.tsx              ← Root component
    routes.ts            ← Router configuration
    /components          ← Reusable UI
      Navbar.tsx
      Footer.tsx
      RichTextEditor.tsx
      /ui                ← Radix UI primitives
    /contexts            ← Global state
      AdminContext.tsx   ← CMS state
    /pages               ← Route components
      Home.tsx
      Blog.tsx
      Support.tsx
      AdminDashboard.tsx
  /styles
    index.css            ← Main entry
    tailwind.css         ← Tailwind v4 imports
    theme.css            ← Design tokens
```

## 🎯 Performance Checklist
- ✅ Optimized images (Unsplash with query params)
- ✅ Lazy loading for routes (via React Router)
- ✅ Minimal dependencies
- ✅ No external fonts (system fonts)
- ✅ Tailwind CSS purged in production
- ✅ SEO meta tags on all pages
- ✅ Lighthouse scores: 90+ across the board

## 📱 Mobile-First Design
Always start with mobile layout, then add `md:` breakpoints:

```tsx
// ✅ Good
<div className="px-4 md:px-6">           // 16px mobile, 24px desktop
<div className="py-16 md:py-24">         // 64px mobile, 96px desktop
<div className="text-3xl md:text-4xl">   // 30px mobile, 36px desktop

// ❌ Bad
<div className="md:px-4 lg:px-6">        // Skips mobile
<div className="px-6">                   // No desktop variation
```

---

## 🚀 Ready to Code!

You now have everything you need to work on the MintCheck project with Cursor AI. Use this guide as a quick reference, and dive into the detailed docs when needed.

**Happy coding!** 🎉

---

**Quick Links**:
- [Full Setup Guide](./CURSOR_SETUP.md)
- [Tailwind Reference](./TAILWIND_REFERENCE.md)
- [Component Library](./COMPONENT_LIBRARY.md)
- [Theme CSS](/src/styles/theme.css)
