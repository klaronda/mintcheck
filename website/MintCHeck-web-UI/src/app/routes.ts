import { createBrowserRouter } from 'react-router';
import Layout from './components/Layout';
import Home from './pages/Home';
import PrivacyPolicy from './pages/PrivacyPolicy';
import TermsOfUse from './pages/TermsOfUse';
import Support from './pages/Support';
import SupportArticle from './pages/SupportArticle';
import Blog from './pages/Blog';
import BlogArticle from './pages/BlogArticle';
import AdminLogin from './pages/AdminLogin';
import AdminDashboard from './pages/AdminDashboard';

export const router = createBrowserRouter([
  {
    Component: Layout,
    children: [
      {
        path: '/',
        Component: Home,
      },
      {
        path: '/privacy',
        Component: PrivacyPolicy,
      },
      {
        path: '/terms',
        Component: TermsOfUse,
      },
      {
        path: '/support',
        Component: Support,
      },
      {
        path: '/support/:slug',
        Component: SupportArticle,
      },
      {
        path: '/blog',
        Component: Blog,
      },
      {
        path: '/blog/:slug',
        Component: BlogArticle,
      },
      {
        path: '/admin/login',
        Component: AdminLogin,
      },
      {
        path: '/admin',
        Component: AdminDashboard,
      },
      {
        path: '/admin/dashboard',
        Component: AdminDashboard,
      },
    ],
  },
]);