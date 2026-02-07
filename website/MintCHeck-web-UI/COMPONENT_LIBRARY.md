# MintCheck Component Library

Complete reference of all components, pages, and utilities in the MintCheck project.

## Core Components

### Navbar (`/src/app/components/Navbar.tsx`)

Desktop and mobile navigation with logo, anchor links, and hamburger menu.

**Props**: None

**Usage**:
```tsx
import Navbar from '@/app/components/Navbar';

<Navbar />
```

**Features**:
- Logo lockup (left)
- Anchor navigation: How It Works, Use Cases, About
- Mobile hamburger menu
- Smooth scroll to sections
- Sticky positioning

---

### Footer (`/src/app/components/Footer.tsx`)

Site footer with four columns, social links, and easter egg.

**Props**: None

**Usage**:
```tsx
import Footer from '@/app/components/Footer';

<Footer />
```

**Features**:
- Four columns: Company, Legal, Support, Resources
- Social media placeholders
- Triple-click easter egg on "© 2026" (opens admin login)
- Email: support@mintcheckapp.com

**Easter Egg**:
```tsx
// Triple-click "© 2026" to navigate to /admin/login
const handleTripleClick = () => {
  if (clickCount === 3) {
    navigate('/admin/login');
  }
};
```

---

### Layout (`/src/app/components/Layout.tsx`)

Root layout wrapper with ScrollToTop and Outlet for React Router.

**Props**: None

**Usage**:
```tsx
import Layout from '@/app/components/Layout';
import { RouterProvider } from 'react-router';

// Automatically used in routes.ts
{
  Component: Layout,
  children: [...]
}
```

**Features**:
- Wraps all pages
- Includes `<ScrollToTop />` for route-based scroll restoration
- Uses React Router `<Outlet />` for child routes

---

### ScrollToTop (`/src/app/components/ScrollToTop.tsx`)

Utility component that scrolls to top on route change.

**Props**: None

**Usage**:
```tsx
import ScrollToTop from '@/app/components/ScrollToTop';

// Used inside Layout.tsx
<ScrollToTop />
```

**Behavior**:
- Automatically scrolls to top when `location.pathname` changes
- Works with React Router navigation

---

### RichTextEditor (`/src/app/components/RichTextEditor.tsx`)

Rich text editor for CMS article body content.

**Props**:
```tsx
{
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
}
```

**Usage**:
```tsx
import RichTextEditor from '@/app/components/RichTextEditor';

<RichTextEditor
  value={formData.body}
  onChange={(value) => setFormData({ ...formData, body: value })}
  placeholder="Write your article content here..."
/>
```

**Features**:
- Basic formatting: Bold, Italic, Underline, Strikethrough
- Headings: H1, H2, H3
- Lists: Bullet, Numbered
- Links
- Code blocks
- Blockquotes
- HTML output stored as string
- Toolbar with Lucide icons

---

## Page Components

### Home (`/src/app/pages/Home.tsx`)

Main landing page with six sections.

**Sections**:
1. **Hero** - Value proposition with iOS app CTA
2. **How It Works** - 3-step process
3. **Use Cases** - Buying vs Owning
4. **OBD-II Scanners** - 3 product cards
5. **Trust & Boundaries** - What MintCheck does/doesn't
6. **About** - Founder story

**SEO**:
- Title: "MintCheck - OBD-II Car Diagnostics Made Simple | iOS App"
- Open Graph tags
- Twitter Card tags
- Canonical URL

**Key Elements**:
- Anchor navigation targets: `#hero`, `#how-it-works`, `#use-cases`, `#about`
- External links to Amazon for OBD-II scanners
- Unsplash images throughout

---

### Blog (`/src/app/pages/Blog.tsx`)

Blog listing page with hero section and article grid.

**Features**:
- Hero section featuring latest blog post
- "More Articles" section with 3 older posts
- Reverse chronological order
- Only published posts shown
- Dynamic routing to `/blog/:slug`

**Layout**:
```tsx
<section>Hero (latest post)</section>
<section>More Articles (3 cards)</section>
```

**SEO**:
- Title: "Blog | MintCheck"
- Description: Latest articles about car diagnostics

---

### BlogArticle (`/src/app/pages/BlogArticle.tsx`)

Individual blog post page.

**Features**:
- Hero image (full width)
- Article title (H1)
- Summary paragraph
- Rich text body content
- 404 redirect if article not found
- Dynamic SEO based on article data

**Layout**:
```tsx
<img /> {/* Hero image */}
<h1>{article.title}</h1>
<p>{article.summary}</p>
<div dangerouslySetInnerHTML={{ __html: article.body }} />
```

---

### Support (`/src/app/pages/Support.tsx`)

Support center landing page with three category sections.

**Categories**:
1. Device Help
2. Using the App
3. Vehicle Support

**Features**:
- Dynamic article count per category
- Only published articles shown
- Links to `/support/:slug`
- Empty state handling

**SEO**:
- Title: "Support Center | MintCheck"
- Description: Help articles and guides

---

### SupportArticle (`/src/app/pages/SupportArticle.tsx`)

Individual support article page.

**Features**:
- Similar to BlogArticle
- Hero image, title, summary, body
- Dynamic SEO
- 404 redirect if not found

---

### PrivacyPolicy (`/src/app/pages/PrivacyPolicy.tsx`)

Privacy policy legal page.

**Features**:
- Standard privacy policy content
- Last updated: January 2026
- SEO optimized
- `noindex, nofollow` meta tags

---

### TermsOfUse (`/src/app/pages/TermsOfUse.tsx`)

Terms of use legal page.

**Features**:
- Standard terms and conditions
- Last updated: January 2026
- SEO optimized
- `noindex, nofollow` meta tags

---

### AdminLogin (`/src/app/pages/AdminLogin.tsx`)

CMS login page with authentication.

**Credentials**:
- Email: `admin@mintcheckapp.com`
- Password: `mintcheck2024`

**Features**:
- Email and password fields
- Client-side authentication
- Redirects to `/admin` on success
- Stores auth token in localStorage
- Prevents access if already logged in

**Usage**:
```tsx
// Access via:
// 1. Direct URL: /admin/login
// 2. Easter egg: Triple-click "© 2026" in footer
```

---

### AdminDashboard (`/src/app/pages/AdminDashboard.tsx`)

CMS dashboard for managing articles.

**Features**:
- View Site button (opens in new tab)
- Logout button
- Create new articles
- Edit existing articles
- Delete articles
- Toggle publish/draft status
- Filter by type: All, Support, Blog
- Rich text editor integration
- Hero image upload (URL or file)
- Auto-generated slugs from titles

**Article Fields**:
```tsx
{
  type: 'support' | 'blog',
  title: string,
  slug: string,
  cardDescription: string,
  summary: string,
  heroImage: string,
  body: string,
  category?: 'Device Help' | 'Using the App' | 'Vehicle Support',
  published: boolean,
}
```

**Layout**:
- Header with "View Site" and "Logout"
- "New Article" button
- Create/Edit form (collapsible)
- Filter tabs
- Article list with thumbnails and actions

**Actions**:
- Edit (opens form)
- Delete (with confirmation)
- Toggle publish/unpublish
- Upload hero image (base64 or URL)

---

## Context Providers

### AdminContext (`/src/app/contexts/AdminContext.tsx`)

Global state management for CMS articles.

**Exports**:
```tsx
export const useAdmin = () => {
  articles: Article[];
  addArticle: (data: Omit<Article, 'id' | 'createdAt'>) => void;
  updateArticle: (id: string, updates: Partial<Article>) => void;
  deleteArticle: (id: string) => void;
};

export const AUTH_KEY = 'mintcheck_admin_auth';
```

**Article Type**:
```tsx
export interface Article {
  id: string;
  type: 'support' | 'blog';
  title: string;
  slug: string;
  cardDescription: string;
  summary: string;
  heroImage: string;
  body: string;
  category?: 'Device Help' | 'Using the App' | 'Vehicle Support';
  published: boolean;
  createdAt: string;
}
```

**Default Articles**:
- 3 support articles (one per category)
- 2 blog posts

**Storage**:
- localStorage key: `mintcheck_cms_articles`
- Persists across sessions
- Max 50 articles supported

**Usage**:
```tsx
import { useAdmin } from '@/app/contexts/AdminContext';

const { articles, addArticle, updateArticle, deleteArticle } = useAdmin();
```

---

## UI Components (`/src/app/components/ui/`)

Radix UI primitives styled with Tailwind (shadcn-style). Only listing commonly used ones:

### Button (`button.tsx`)
```tsx
import { Button } from '@/app/components/ui/button';

<Button variant="default">Primary</Button>
<Button variant="outline">Secondary</Button>
<Button variant="ghost">Ghost</Button>
<Button variant="destructive">Delete</Button>
```

### Card (`card.tsx`)
```tsx
import { Card, CardHeader, CardTitle, CardContent } from '@/app/components/ui/card';

<Card>
  <CardHeader>
    <CardTitle>Title</CardTitle>
  </CardHeader>
  <CardContent>Content</CardContent>
</Card>
```

### Dialog (`dialog.tsx`)
```tsx
import { Dialog, DialogTrigger, DialogContent, DialogHeader, DialogTitle } from '@/app/components/ui/dialog';

<Dialog>
  <DialogTrigger>Open</DialogTrigger>
  <DialogContent>
    <DialogHeader>
      <DialogTitle>Title</DialogTitle>
    </DialogHeader>
    <p>Content</p>
  </DialogContent>
</Dialog>
```

### Input (`input.tsx`)
```tsx
import { Input } from '@/app/components/ui/input';

<Input type="text" placeholder="Enter text" />
```

### Label (`label.tsx`)
```tsx
import { Label } from '@/app/components/ui/label';

<Label htmlFor="input-id">Label text</Label>
```

### Select (`select.tsx`)
```tsx
import { Select, SelectTrigger, SelectValue, SelectContent, SelectItem } from '@/app/components/ui/select';

<Select>
  <SelectTrigger>
    <SelectValue placeholder="Select option" />
  </SelectTrigger>
  <SelectContent>
    <SelectItem value="1">Option 1</SelectItem>
    <SelectItem value="2">Option 2</SelectItem>
  </SelectContent>
</Select>
```

### Textarea (`textarea.tsx`)
```tsx
import { Textarea } from '@/app/components/ui/textarea';

<Textarea placeholder="Enter text" rows={3} />
```

### Checkbox (`checkbox.tsx`)
```tsx
import { Checkbox } from '@/app/components/ui/checkbox';

<Checkbox id="check" checked={value} onCheckedChange={setValue} />
```

### Tabs (`tabs.tsx`)
```tsx
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/app/components/ui/tabs';

<Tabs defaultValue="tab1">
  <TabsList>
    <TabsTrigger value="tab1">Tab 1</TabsTrigger>
    <TabsTrigger value="tab2">Tab 2</TabsTrigger>
  </TabsList>
  <TabsContent value="tab1">Content 1</TabsContent>
  <TabsContent value="tab2">Content 2</TabsContent>
</Tabs>
```

**Full list available** in `/src/app/components/ui/` directory (40+ components).

---

## Protected Components

### ImageWithFallback (`/src/app/components/figma/ImageWithFallback.tsx`)

**DO NOT MODIFY** - Protected Figma component

Fallback image component for handling broken images.

**Usage**:
```tsx
import { ImageWithFallback } from '@/app/components/figma/ImageWithFallback';

<ImageWithFallback src={imageUrl} alt="Description" />
```

---

## Routing Configuration

### Router (`/src/app/routes.ts`)

React Router v7 configuration using Data mode.

**Routes**:
```tsx
/                    → Home
/privacy             → PrivacyPolicy
/terms               → TermsOfUse
/support             → Support
/support/:slug       → SupportArticle
/blog                → Blog
/blog/:slug          → BlogArticle
/admin/login         → AdminLogin
/admin               → AdminDashboard
/admin/dashboard     → AdminDashboard (alias)
```

**Layout Structure**:
```tsx
<Layout>
  <Outlet /> {/* All child routes */}
</Layout>
```

---

## Utilities

### `clsx` & `cn` (`/src/app/components/ui/utils.ts`)

Utility for conditionally joining classNames.

**Usage**:
```tsx
import { cn } from '@/app/components/ui/utils';

<div className={cn(
  "base-classes",
  isActive && "active-classes",
  "more-classes"
)} />
```

---

## Icon Library (Lucide React)

All icons imported from `lucide-react`:

**Common Icons**:
```tsx
import { 
  Apple,           // iOS icon
  Plug,            // OBD-II scanner
  Scan,            // Scanning
  FileText,        // Article/document
  Check,           // Success/checkmark
  X,               // Close/remove
  Mail,            // Email
  ExternalLink,    // External link
  Menu,            // Hamburger menu
  LogOut,          // Logout
  Edit,            // Edit
  Trash2,          // Delete
  Eye,             // Visible/publish
  EyeOff,          // Hidden/unpublish
  Plus,            // Add/create
  Upload,          // Upload file
} from 'lucide-react';
```

**Usage**:
```tsx
<Apple className="w-5 h-5" />
<Scan className="w-6 h-6 text-primary" />
```

---

## Animation Library (Motion)

Framer Motion rebranded as Motion.

**Install**:
```bash
pnpm add motion
```

**Import**:
```tsx
import { motion } from 'motion/react';
```

**Usage**:
```tsx
<motion.div
  initial={{ opacity: 0 }}
  animate={{ opacity: 1 }}
  transition={{ duration: 0.5 }}
>
  Animated content
</motion.div>
```

---

## SEO Helper (react-helmet-async)

Manage document head with React components.

**Setup** (already in App.tsx):
```tsx
import { HelmetProvider } from 'react-helmet-async';

<HelmetProvider>
  <RouterProvider router={router} />
</HelmetProvider>
```

**Usage in Pages**:
```tsx
import { Helmet } from 'react-helmet-async';

<Helmet>
  <title>Page Title | MintCheck</title>
  <meta name="description" content="Page description" />
  <meta property="og:title" content="OG Title" />
  <meta name="twitter:card" content="summary_large_image" />
</Helmet>
```

---

## Component Best Practices

### 1. Use Absolute Imports
```tsx
✅ import { Navbar } from '@/app/components/Navbar';
❌ import { Navbar } from '../components/Navbar';
```

### 2. Follow Naming Conventions
- Components: PascalCase (`Navbar.tsx`)
- Utilities: camelCase (`utils.ts`)
- Pages: PascalCase (`Home.tsx`)
- Routes: kebab-case in URLs (`/support-article`)

### 3. Consistent Styling
```tsx
// Use Tailwind classes
<div className="bg-primary text-white px-6 py-4 rounded-lg">

// Use inline styles for font-weight (overrides base layer)
<h1 style={{ fontWeight: 600 }}>Title</h1>

// Use custom hex for specific shades
<section style={{ backgroundColor: '#FCFCFB' }}>
```

### 4. SEO on Every Page
```tsx
<Helmet>
  <title>Page Title | MintCheck</title>
  <meta name="description" content="..." />
  <link rel="canonical" href="https://mintcheckapp.com/path" />
  {/* + OG tags, Twitter cards */}
</Helmet>
```

### 5. Responsive Design
```tsx
// Mobile-first approach
<div className="grid grid-cols-1 md:grid-cols-2 gap-6">
<h1 className="text-3xl md:text-4xl lg:text-5xl">
<div className="px-4 md:px-6 py-16 md:py-24">
```

### 6. Accessibility
```tsx
// Semantic HTML
<nav>, <main>, <section>, <article>, <footer>

// Alt text for images
<img src="..." alt="Descriptive text" />

// ARIA labels where needed
<button aria-label="Close menu">
```

---

## Development Tips

### Adding a New Page
1. Create in `/src/app/pages/NewPage.tsx`
2. Add route in `/src/app/routes.ts`
3. Include `<Helmet>` for SEO
4. Use existing layout patterns
5. Import with `@` alias

### Adding a New Component
1. Create in `/src/app/components/NewComponent.tsx`
2. Export as default or named export
3. Document props with TypeScript
4. Use Tailwind for styling
5. Make responsive with breakpoints

### Modifying Styles
1. Check `/src/styles/theme.css` for design tokens
2. Use existing Tailwind classes when possible
3. Add new CSS variables in `:root` if needed
4. Test on mobile, tablet, desktop

### Managing Content (CMS)
1. Login at `/admin`
2. Create/edit articles via rich text editor
3. Upload hero images (base64 or URL)
4. Preview articles before publishing
5. Articles stored in localStorage (no database)

---

**Last Updated**: 2026-01-23
