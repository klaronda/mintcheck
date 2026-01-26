import { createBrowserRouter } from 'react-router';
import { lazy, Suspense } from 'react';
import Layout from './components/Layout';

// Lazy load components for code splitting
const Home = lazy(() => import('./pages/Home'));
const PrivacyPolicy = lazy(() => import('./pages/PrivacyPolicy'));
const TermsOfUse = lazy(() => import('./pages/TermsOfUse'));
const Support = lazy(() => import('./pages/Support'));
const SupportArticle = lazy(() => import('./pages/SupportArticle'));
const Blog = lazy(() => import('./pages/Blog'));
const BlogArticle = lazy(() => import('./pages/BlogArticle'));
const AdminLogin = lazy(() => import('./pages/AdminLogin'));
const AdminDashboard = lazy(() => import('./pages/AdminDashboard'));
const Download = lazy(() => import('./pages/Download'));
const Contact = lazy(() => import('./pages/Contact'));
const ReportPage = lazy(() => import('./pages/ReportPage'));

// Loading fallback component
const LoadingFallback = () => (
  <div className="min-h-screen bg-white flex items-center justify-center">
    <div className="text-center">
      <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
      <p className="text-muted-foreground">Loading...</p>
    </div>
  </div>
);

// Wrapper component for Suspense
const LazyComponent = ({ Component }: { Component: React.LazyExoticComponent<() => JSX.Element> }) => (
  <Suspense fallback={<LoadingFallback />}>
    <Component />
  </Suspense>
);

export const router = createBrowserRouter([
  {
    Component: Layout,
    children: [
      {
        path: '/',
        element: <LazyComponent Component={Home} />,
      },
      {
        path: '/download',
        element: <LazyComponent Component={Download} />,
      },
      {
        path: '/contact',
        element: <LazyComponent Component={Contact} />,
      },
      {
        path: '/report/:shareCode',
        element: <LazyComponent Component={ReportPage} />,
      },
      {
        path: '/privacy',
        element: <LazyComponent Component={PrivacyPolicy} />,
      },
      {
        path: '/terms',
        element: <LazyComponent Component={TermsOfUse} />,
      },
      {
        path: '/support',
        element: <LazyComponent Component={Support} />,
      },
      {
        path: '/support/:slug',
        element: <LazyComponent Component={SupportArticle} />,
      },
      {
        path: '/blog',
        element: <LazyComponent Component={Blog} />,
      },
      {
        path: '/blog/:slug',
        element: <LazyComponent Component={BlogArticle} />,
      },
      {
        path: '/admin/login',
        element: <LazyComponent Component={AdminLogin} />,
      },
      {
        path: '/admin',
        element: <LazyComponent Component={AdminDashboard} />,
      },
      {
        path: '/admin/dashboard',
        element: <LazyComponent Component={AdminDashboard} />,
      },
    ],
  },
]);
