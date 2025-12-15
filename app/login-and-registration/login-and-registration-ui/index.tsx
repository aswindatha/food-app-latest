import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import LoginRegisterPage from './LoginRegisterPage';
import DonorDashboardPage from '../../donor/donor-ui/DonorDashboard';

// Basic placeholders for other dashboards
const VolunteerDashboard = () => <h1>Volunteer Dashboard</h1>;
const OrganizationDashboard = () => <h1>Organization Dashboard</h1>;
const AdminDashboard = () => <h1>Admin Dashboard</h1>;

const App = () => (
  <BrowserRouter>
    <Routes>
      <Route path="/" element={<LoginRegisterPage />} />
      <Route path="/donor/dashboard" element={<DonorDashboardPage />} />
      <Route path="/volunteer/dashboard" element={<VolunteerDashboard />} />
      <Route path="/organization/dashboard" element={<OrganizationDashboard />} />
      <Route path="/admin/dashboard" element={<AdminDashboard />} />
    </Routes>
  </BrowserRouter>
);

const root = ReactDOM.createRoot(
  document.getElementById('root') as HTMLElement
);

root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
