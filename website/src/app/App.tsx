import { RouterProvider } from 'react-router';
import { router } from './routes';
import { HelmetProvider } from 'react-helmet-async';
import { AdminProvider } from './contexts/AdminContext';

export default function App() {
  return (
    <HelmetProvider>
      <AdminProvider>
        <RouterProvider router={router} />
      </AdminProvider>
    </HelmetProvider>
  );
}
