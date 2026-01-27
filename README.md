# MintCheck - Marketing Website

A single-page marketing website for MintCheck, an iOS app that helps people make smarter decisions about used cars through OBD-II scanner diagnostics.

## 📚 Documentation

This project includes comprehensive documentation for **Cursor AI** and developers:

### Quick Start
- **[CURSOR_QUICKSTART.md](./CURSOR_QUICKSTART.md)** - Fast reference for Cursor AI (START HERE!)
- **[.cursorrules](./.cursorrules)** - Cursor-specific rules and patterns

### Detailed References
- **[CURSOR_SETUP.md](./CURSOR_SETUP.md)** - Complete project setup and configuration
- **[TAILWIND_REFERENCE.md](./TAILWIND_REFERENCE.md)** - All Tailwind CSS classes and patterns
- **[COMPONENT_LIBRARY.md](./COMPONENT_LIBRARY.md)** - All components, props, and usage examples

## 🚀 Tech Stack

- **React** 18.3.1
- **Vite** 6.3.5
- **Tailwind CSS** v4.1.12 (CSS-based, no config file)
- **React Router** 7.12.0 (Data mode)
- **TypeScript** enabled
- **Supabase** - Backend (CMS, contact forms)
- **SEO**: react-helmet-async
- **Icons**: Lucide React
- **Animation**: Motion (Framer Motion)

## 📦 Installation

```bash
# Install dependencies
npm install

# Development server
npm run dev

# Production build
npm run build
```

## 🔧 Environment Variables

Create a `.env` file in the root directory:

```bash
VITE_SUPABASE_URL=https://iawkgqbrxoctatfrjpli.supabase.co
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

## 🚀 Deployment to Vercel

1. Push your code to GitHub
2. Import the project in Vercel
3. Add environment variables in Vercel dashboard:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
4. Deploy!

The `vercel.json` file is already configured for SPA routing.

## 🎨 Design System

### Brand Colors
- **Primary**: `#3EB489` (Mint Green)
- **Backgrounds**: White, `#FCFCFB`, `#F8F8F7`
- **Text**: `#1a1a1a` (foreground), `#666666` (muted)
- **Border**: `#e5e5e5`

### Typography
- **Font**: System fonts (default browser stack)
- **Headings**: Semibold (600)
- **Body**: Regular (400)

### Spacing
- **Sections**: `py-24` (desktop), `py-16` (mobile)
- **Container**: `max-w-4xl` or `max-w-6xl`
- **Padding**: `px-6` horizontal

## 📁 Project Structure

```
/src
  /app
    App.tsx                    # Root component
    routes.ts                  # React Router config
    /components
      Navbar.tsx               # Navigation
      Footer.tsx               # Footer with easter egg
      RichTextEditor.tsx       # CMS editor
      /ui                      # Radix UI components
      /figma                   # Protected Figma components
    /contexts
      AdminContext.tsx         # CMS state management
    /pages
      Home.tsx                 # Landing page
      Blog.tsx                 # Blog listing
      BlogArticle.tsx          # Individual blog post
      Support.tsx              # Support center
      SupportArticle.tsx       # Support article
      PrivacyPolicy.tsx        # Legal
      TermsOfUse.tsx           # Legal
      AdminLogin.tsx           # CMS login
      AdminDashboard.tsx       # CMS dashboard
  /styles
    index.css                  # Main CSS entry
    tailwind.css               # Tailwind v4 imports
    theme.css                  # Design tokens
```

## 🌐 Routes

| Route | Component | Description |
|-------|-----------|-------------|
| `/` | Home | Main landing page |
| `/download` | Download | App download page |
| `/contact` | Contact | Contact form |
| `/privacy` | PrivacyPolicy | Privacy policy |
| `/terms` | TermsOfUse | Terms of use |
| `/support` | Support | Support center |
| `/support/:slug` | SupportArticle | Individual support article |
| `/blog` | Blog | Blog listing |
| `/blog/:slug` | BlogArticle | Individual blog post |
| `/admin/login` | AdminLogin | CMS login |
| `/admin` | AdminDashboard | CMS dashboard |

## 🔑 CMS Access

### Login Credentials
- **URL**: `/admin/login`
- **Email**: `admin@mintcheckapp.com`
- **Password**: `mintcheck2024`
- **Easter Egg**: Triple-click "© 2026" in footer

### Features
- Rich text editor with formatting
- Image upload (URL or base64)
- Up to 50 articles (support + blog)
- Three support categories: Device Help, Using the App, Vehicle Support
- Draft/publish toggle
- Auto-generated slugs

## 📱 Responsive Design

Mobile-first approach with breakpoints:
- **Mobile**: Default (< 768px)
- **Desktop**: `md:` breakpoint (≥ 768px)
- **Large**: `lg:` (≥ 1024px)

## 🎯 SEO Optimization

Every page includes:
- Meta title and description
- Canonical URLs
- Open Graph tags
- Twitter Card tags
- Structured data ready

Target Lighthouse scores: **90+** across all metrics

## 🛠️ Development

### Code Style
- Use `@` alias for absolute imports
- Inline `style={{ fontWeight: 600 }}` for headings
- Tailwind CSS for all styling
- TypeScript for type safety
- React functional components with hooks

### Example Component
```tsx
import { Helmet } from 'react-helmet-async';
import { Apple } from 'lucide-react';

export default function Example() {
  return (
    <div className="min-h-screen bg-white">
      <Helmet>
        <title>Example | MintCheck</title>
      </Helmet>
      
      <section className="max-w-4xl mx-auto px-6 py-24">
        <h1 className="text-4xl mb-6" style={{ fontWeight: 600 }}>
          Example Page
        </h1>
        
        <button className="inline-flex items-center gap-2 bg-primary text-primary-foreground px-8 py-4 rounded-lg hover:opacity-90">
          <Apple className="w-5 h-5" />
          Get the iOS App
        </button>
      </section>
    </div>
  );
}
```

## 🚨 Important Notes

### Protected Files (DO NOT MODIFY)
- `/src/app/components/figma/ImageWithFallback.tsx`
- `/pnpm-lock.yaml`

### Tailwind CSS v4
- No `tailwind.config.js` file
- All configuration in `/src/styles/theme.css`
- Uses CSS custom properties
- Design tokens via `@theme inline`

### Absolute Imports
Always use `@` alias:
```tsx
✅ import { Navbar } from '@/app/components/Navbar';
❌ import { Navbar } from '../components/Navbar';
```

## 📖 Learn More

- **[Vite Documentation](https://vite.dev/)**
- **[React Documentation](https://react.dev/)**
- **[Tailwind CSS v4](https://tailwindcss.com/docs)**
- **[React Router v7](https://reactrouter.com/)**
- **[Lucide Icons](https://lucide.dev/)**

## 🎨 Brand Guidelines

### Voice & Tone
- **Reading Level**: 10th grade
- **Tone**: Calm, professional, helpful
- **Language**: Simple, clear, no jargon

### Visual Style
- **Aesthetic**: Generous whitespace, subtle borders
- **No**: Gradients, illustrations, gimmicky UI
- **Colors**: Mint green accent, neutral grays

### Content Examples
✅ "Make smarter decisions about used cars"  
✅ "Know what you're buying — or what your car needs — in plain English"  
❌ "Leverage advanced OBD-II diagnostic protocols"

## 📧 Contact

- **Email**: support@mintcheckapp.com
- **Website**: https://mintcheckapp.com

## 📄 License

Proprietary - © 2026 MintCheck. All rights reserved.

---

**Built with ❤️ for car buyers and owners everywhere.**
