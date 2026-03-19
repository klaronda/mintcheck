# 📚 MintCheck - Complete Documentation Index

Welcome! This project includes comprehensive documentation to help you (and Cursor AI) understand and work with the MintCheck codebase efficiently.

## 🚀 Start Here

### For Cursor AI Users
1. **[.cursorrules](./.cursorrules)** - Essential rules for Cursor AI (read this first!)
2. **[CURSOR_QUICKSTART.md](./CURSOR_QUICKSTART.md)** - Quick reference guide (5-minute read)
3. **[README.md](./README.md)** - Project overview

### For Developers
1. **[README.md](./README.md)** - Project overview and getting started
2. **[CURSOR_SETUP.md](./CURSOR_SETUP.md)** - Complete setup guide
3. **[COMPONENT_LIBRARY.md](./COMPONENT_LIBRARY.md)** - Component reference

---

## 📖 Documentation Files

### 1. [.cursorrules](./.cursorrules)
**What**: Cursor AI configuration file  
**When to use**: Automatically read by Cursor AI  
**Contains**:
- Import patterns
- Tailwind CSS rules
- Common code patterns
- Brand guidelines
- Quick task templates

### 2. [README.md](./README.md)
**What**: Main project documentation  
**When to use**: First-time setup, project overview  
**Contains**:
- Tech stack overview
- Installation instructions
- Project structure
- Development guidelines
- Contact information

### 3. [CURSOR_QUICKSTART.md](./CURSOR_QUICKSTART.md)
**What**: Fast reference for Cursor AI  
**When to use**: Quick lookups, common tasks  
**Contains**:
- Design system cheat sheet
- Common component patterns
- Quick task templates
- Troubleshooting
- Mobile-first design patterns

### 4. [CURSOR_SETUP.md](./CURSOR_SETUP.md)
**What**: Complete project setup and configuration  
**When to use**: Deep dive into project architecture  
**Contains**:
- Vite configuration details
- Tailwind CSS v4 setup
- Design tokens explanation
- Routing configuration
- CMS system documentation
- SEO configuration
- Development workflow

### 5. [TAILWIND_REFERENCE.md](./TAILWIND_REFERENCE.md)
**What**: Comprehensive Tailwind CSS class reference  
**When to use**: Styling components, looking up classes  
**Contains**:
- All design tokens (colors, spacing, etc.)
- Common component patterns
- Responsive breakpoints
- Utility classes
- Custom inline styles
- Dark mode support (future)

### 6. [COMPONENT_LIBRARY.md](./COMPONENT_LIBRARY.md)
**What**: Complete component API reference  
**When to use**: Using existing components, creating new ones  
**Contains**:
- All component props and usage
- Page component documentation
- Context providers (AdminContext)
- UI components (Radix UI)
- Icon library reference
- Animation library usage
- SEO helpers

---

## 🗂️ How to Use This Documentation

### Scenario 1: "I'm new to this project"
Read in this order:
1. [README.md](./README.md) - Get the big picture
2. [CURSOR_QUICKSTART.md](./CURSOR_QUICKSTART.md) - Learn the patterns
3. [CURSOR_SETUP.md](./CURSOR_SETUP.md) - Understand the architecture

### Scenario 2: "I need to add a new page"
Quick path:
1. [CURSOR_QUICKSTART.md](./CURSOR_QUICKSTART.md) → "Quick Tasks" → "Add a New Page"
2. [COMPONENT_LIBRARY.md](./COMPONENT_LIBRARY.md) → "Page Components" (for examples)
3. [TAILWIND_REFERENCE.md](./TAILWIND_REFERENCE.md) → "Common Patterns" (for styling)

### Scenario 3: "I need to style a component"
Quick path:
1. [TAILWIND_REFERENCE.md](./TAILWIND_REFERENCE.md) → "Common Component Patterns"
2. [CURSOR_QUICKSTART.md](./CURSOR_QUICKSTART.md) → "Design System Cheat Sheet"
3. `/src/styles/theme.css` → Check design tokens

### Scenario 4: "I need to use an existing component"
Quick path:
1. [COMPONENT_LIBRARY.md](./COMPONENT_LIBRARY.md) → Find your component
2. Check props and usage examples
3. Import with `@` alias

### Scenario 5: "I'm working with the CMS"
Quick path:
1. [CURSOR_SETUP.md](./CURSOR_SETUP.md) → "CMS System"
2. [COMPONENT_LIBRARY.md](./COMPONENT_LIBRARY.md) → "AdminContext"
3. Login at `/admin` with credentials

### Scenario 6: "Something's not working"
Quick path:
1. [CURSOR_QUICKSTART.md](./CURSOR_QUICKSTART.md) → "Common Issues"
2. [.cursorrules](./.cursorrules) → Check import patterns and rules
3. [CURSOR_SETUP.md](./CURSOR_SETUP.md) → "Important Reminders"

---

## 🎯 Quick Reference Cards

### Import Pattern
```tsx
✅ import { X } from '@/app/components/Component';
❌ import { X } from '../components/Component';
```

### Font Weight
```tsx
✅ <h1 style={{ fontWeight: 600 }}>Title</h1>
❌ <h1 className="font-semibold">Title</h1>
```

### Brand Color
```tsx
✅ className="bg-primary text-primary-foreground"
✅ className="bg-[#3EB489] text-white"
```

### SEO Template
```tsx
<Helmet>
  <title>Page Title | MintCheck</title>
  <meta name="description" content="..." />
</Helmet>
```

---

## 📂 Project File Structure

### Root Level
- `/.cursorrules` - Cursor AI rules
- `/README.md` - Main documentation
- `/package.json` - Dependencies
- `/vite.config.ts` - Vite configuration
- `/postcss.config.mjs` - PostCSS config
- `/DOCUMENTATION_INDEX.md` - This file!

### Documentation
- `/CURSOR_QUICKSTART.md` - Quick reference
- `/CURSOR_SETUP.md` - Complete setup
- `/TAILWIND_REFERENCE.md` - Tailwind classes
- `/COMPONENT_LIBRARY.md` - Component APIs

### Source Code
- `/src/app/App.tsx` - Root component
- `/src/app/routes.ts` - Routing config
- `/src/app/components/` - Reusable components
- `/src/app/pages/` - Page components
- `/src/app/contexts/` - Global state
- `/src/styles/` - CSS and design tokens

---

## 🔍 Search Guide

Looking for something specific? Use this index:

### Design & Styling
- **Colors**: [TAILWIND_REFERENCE.md](./TAILWIND_REFERENCE.md) → "Design Tokens"
- **Typography**: [CURSOR_QUICKSTART.md](./CURSOR_QUICKSTART.md) → "Typography Patterns"
- **Layout**: [TAILWIND_REFERENCE.md](./TAILWIND_REFERENCE.md) → "Containers & Sections"
- **Responsive**: [TAILWIND_REFERENCE.md](./TAILWIND_REFERENCE.md) → "Responsive Breakpoints"
- **Buttons**: [TAILWIND_REFERENCE.md](./TAILWIND_REFERENCE.md) → "Buttons"
- **Cards**: [TAILWIND_REFERENCE.md](./TAILWIND_REFERENCE.md) → "Cards"

### Components
- **Navbar**: [COMPONENT_LIBRARY.md](./COMPONENT_LIBRARY.md) → "Navbar"
- **Footer**: [COMPONENT_LIBRARY.md](./COMPONENT_LIBRARY.md) → "Footer"
- **Forms**: [COMPONENT_LIBRARY.md](./COMPONENT_LIBRARY.md) → "UI Components"
- **Icons**: [COMPONENT_LIBRARY.md](./COMPONENT_LIBRARY.md) → "Icon Library"
- **Rich Text**: [COMPONENT_LIBRARY.md](./COMPONENT_LIBRARY.md) → "RichTextEditor"

### Configuration
- **Vite**: [CURSOR_SETUP.md](./CURSOR_SETUP.md) → "Vite Configuration"
- **Tailwind**: [CURSOR_SETUP.md](./CURSOR_SETUP.md) → "Tailwind CSS v4 Setup"
- **Routing**: [CURSOR_SETUP.md](./CURSOR_SETUP.md) → "Routing Configuration"
- **SEO**: [CURSOR_SETUP.md](./CURSOR_SETUP.md) → "SEO Configuration"

### Features
- **CMS**: [CURSOR_SETUP.md](./CURSOR_SETUP.md) → "CMS System"
- **Blog**: [COMPONENT_LIBRARY.md](./COMPONENT_LIBRARY.md) → "Blog"
- **Support**: [COMPONENT_LIBRARY.md](./COMPONENT_LIBRARY.md) → "Support"
- **Admin**: [COMPONENT_LIBRARY.md](./COMPONENT_LIBRARY.md) → "AdminDashboard"

---

## 🎓 Learning Path

### Beginner
1. Read [README.md](./README.md) - Understand the project
2. Explore `/src/app/pages/Home.tsx` - See a complete example
3. Review [CURSOR_QUICKSTART.md](./CURSOR_QUICKSTART.md) - Learn patterns

### Intermediate
1. Study [TAILWIND_REFERENCE.md](./TAILWIND_REFERENCE.md) - Master styling
2. Read [COMPONENT_LIBRARY.md](./COMPONENT_LIBRARY.md) - Understand components
3. Explore `/src/app/components/` - See implementations

### Advanced
1. Review [CURSOR_SETUP.md](./CURSOR_SETUP.md) - Deep dive into architecture
2. Study `/src/app/contexts/AdminContext.tsx` - State management
3. Explore `/src/styles/theme.css` - Design system

---

## 🛠️ Maintenance

### Updating Documentation
When making significant changes to the project:

1. Update [README.md](./README.md) if tech stack changes
2. Update [CURSOR_SETUP.md](./CURSOR_SETUP.md) for configuration changes
3. Update [TAILWIND_REFERENCE.md](./TAILWIND_REFERENCE.md) for new styles
4. Update [COMPONENT_LIBRARY.md](./COMPONENT_LIBRARY.md) for new components
5. Update [.cursorrules](./.cursorrules) for new patterns

### Documentation Checklist
- [ ] README.md reflects current tech stack
- [ ] All new components documented in COMPONENT_LIBRARY.md
- [ ] New Tailwind patterns added to TAILWIND_REFERENCE.md
- [ ] .cursorrules updated with new conventions
- [ ] CURSOR_QUICKSTART.md reflects latest patterns

---

## 💡 Tips for Success

### For Cursor AI
- Always check [.cursorrules](./.cursorrules) first
- Reference [CURSOR_QUICKSTART.md](./CURSOR_QUICKSTART.md) for patterns
- Use [TAILWIND_REFERENCE.md](./TAILWIND_REFERENCE.md) for styling

### For Developers
- Bookmark [CURSOR_QUICKSTART.md](./CURSOR_QUICKSTART.md)
- Keep [TAILWIND_REFERENCE.md](./TAILWIND_REFERENCE.md) open while styling
- Refer to [COMPONENT_LIBRARY.md](./COMPONENT_LIBRARY.md) when using components

### For Contributors
- Read all documentation before making changes
- Follow patterns in [.cursorrules](./.cursorrules)
- Update docs when adding features

---

## 📞 Need Help?

1. **Check the docs** - Your answer is probably here
2. **Search the codebase** - Look for similar implementations
3. **Ask the team** - support@mintcheckapp.com

---

**Happy coding! 🎉**

Last Updated: 2026-01-23
