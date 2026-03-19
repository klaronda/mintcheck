import { Outlet } from 'react-router';
import ScrollToTop from './ScrollToTop';

export default function Layout() {
  return (
    <>
      <ScrollToTop />
      <Outlet />
    </>
  );
}
