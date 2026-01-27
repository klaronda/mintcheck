import { createBrowserRouter } from 'react-router';
import Layout from './components/Layout';
import Home from './pages/Home';
import Support from './pages/Support';
import SupportArticle from './pages/SupportArticle';
import Blog from './pages/Blog';
import BlogArticle from './pages/BlogArticle';
import PrivacyPolicy from './pages/PrivacyPolicy';
import TermsOfUse from './pages/TermsOfUse';
import AdminLogin from './pages/AdminLogin';
import AdminDashboard from './pages/AdminDashboard';
import ReportPage from './pages/ReportPage';
import Download from './pages/Download';

export const router = createBrowserRouter([
  {
    path: '/',
    element: <Layout />,
    children: [
      { index: true, element: <Home /> },
      { path: 'download', element: <Download /> },
      { path: 'support', element: <Support /> },
      { path: 'support/:slug', element: <SupportArticle /> },
      { path: 'blog', element: <Blog /> },
      { path: 'blog/:slug', element: <BlogArticle /> },
      { path: 'privacy', element: <PrivacyPolicy /> },
      { path: 'terms', element: <TermsOfUse /> },
      { path: 'admin/login', element: <AdminLogin /> },
      { path: 'admin/dashboard', element: <AdminDashboard /> },
      { path: 'report/:shareCode', element: <ReportPage /> },
    ],
  },
]);
