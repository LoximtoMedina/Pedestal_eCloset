/* ==========================================================================
   1. DEPENDENCIAS DE ENRUTAMIENTO Y CONTEXTO DE SESIÓN
   ========================================================================== */
import { Routes, Route, Navigate, useNavigate } from 'react-router';
import { useAuth, getDashboardRoute } from '../context/authContext';

/* 
==========================================================================
  2. LAYOUTS, GUARDAS DE RUTA Y VISTAS
========================================================================== 
*/
import PublicLayout from '../layouts/publicLayout';
import DashboardLayout from '../layouts/dashboardLayout';
import ProtectedRoute from './protectedRoutes';

// Ruta de Admin
import RolesAdmin from '../pages/admin/roles/roles';
import AreasAdmin from '../pages/admin/areas/areas';
import StoresAdmin from '../pages/admin/stores/stores';

// Ruta de Auth
import Login from '../pages/auth/login/login';
import SignUp from '../pages/auth/signUp/signUp';

// Ruta de Dashboards
import AreaDashboard from '../pages/dashboards/areaDashboard/areaDashboard';
import NationalDashboard from '../pages/dashboards/nationalDashboard/nationalDashboard';
import StoreDashboard from '../pages/dashboards/storeDashboard/storeDashboard';

// Ruta de eCloset
import ModelPoses from '../pages/ecloset/modelPoses/modelPoses';
import OutfitPlanner from '../pages/ecloset/outfitPlanner/outfitPlanner';
import TryOn from '../pages/ecloset/tryOn/tryOn';

// Ruta de Home
import Home from '../pages/home/home';

// Ruta de HR
import Employees from '../pages/hr/employees/employees';
import PayRoll from '../pages/hr/payRoll/payRoll';

// Ruta de POS
import POS from '../pages/pos/posTerminal';

// Ruta de Inventory
import Racks from '../pages/inventory/racks/racks';
import Stock from '../pages/inventory/stock/stock';
import StockMovements from '../pages/inventory/stockMovements/stockMovements';

// Ruta de Promotions
import Coupons from '../pages/promotions/coupons/coupons'
import Discounts from '../pages/promotions/discounts/discounts'

// Ruta de Purchases
import PurchaseOrders from '../pages/purchases/purchaseOrders/purchaseOrders'
import Suppliers from '../pages/purchases/suppliers/suppliers'

// Ruta de Shop
import Cart from '../pages/shop/cart/cart';
import Catalog from '../pages/shop/catalog/catalog'; 
import CheckOut from '../pages/shop/checkout/checkout'
import ProductDetail from '../pages/shop/productDetail/productDetail'

// Ruta de User
import Profile from '../pages/user/profile/profile';
import MyOrders from '../pages/user/myOrders/myOrders';


/* ==========================================================================
   3. ENRUTADOR PRINCIPAL DE LA APLICACIÓN
   ========================================================================== */
function AppRoutes() {
  const { isAuthenticated, user, loginMock } = useAuth();
  const navigate = useNavigate();
  const dashboardTarget = getDashboardRoute(user?.role);

  return (
    <Routes>
      {/* Rutas de auth */}
      <Route
        path="/login"
        element={
          isAuthenticated ? (
            <Navigate to="/" replace />
          ) : (
            <Login
              onRegisterClick={() => navigate('/signup')}
              onSubmit={({ email }) => {
                loginMock({ identifier: email });
                navigate('/');
              }}
            />
          )
        }
      />

      <Route
        path="/signup"
        element={
          isAuthenticated ? (
            <Navigate to="/" replace />
          ) : (
            <SignUp
              onLoginClick={() => navigate('/login')}
              onSubmit={(data) => {
                loginMock({
                  correo: data.correo,
                  nombreUsuario: data.nombreUsuario,
                  primerNombre: data.primerNombre,
                  primerApellido: data.primerApellido,
                });
                navigate('/');
              }}
            />
          )
        }
      />

      {/* Rutas que UTILIZAN el LAYOUT PÚBLICO y que NO NECESITAN una SESIÓN ACTIVA */}
      <Route element={<PublicLayout />}>
        {/* Home */}
        <Route path="/" element={<Home />} />

        {/* Shop */}
        <Route path="/shop/catalog" element={<Catalog />} />
        <Route path="/shop/catalog/product-detail" element={<ProductDetail />} />
      </Route>

      
      <Route element={<ProtectedRoute />}>
        {/* Rutas que UTILIZAN el LAYOUT PÚBLICO y que NECESITAN una SESIÓN ACTIVA */}
        <Route element={<PublicLayout />}>
          {/* eCloset */}
          <Route path="/ecloset/model-poses" element={<ModelPoses />} />
          <Route path="/ecloset/outfit-planner" element={<OutfitPlanner />} />
          <Route path="/ecloset/try-on" element={<TryOn />} />

          {/* User */}
          <Route path="/user/my-orders" element={<MyOrders />} />
          <Route path="/user/profile" element={<Profile />} />

          {/* Shop */}
          <Route path="/shop/cart" element={<Cart />} />
          <Route path="/shop/cart/checkout" element={<CheckOut />} />
        </Route>

        {/* Rutas que UTILIZAN el LAYOUT de DASHBOARD y que NECESITAN una SESIÓN ACTIVA */}
        <Route element={<DashboardLayout />}>
          <Route path="/dashboard" element={<Navigate to={dashboardTarget} replace />} />
          {/* Admin */}
          <Route path="/admin/areas" element={<AreasAdmin />} />
          <Route path="/admin/roles" element={<RolesAdmin />} />
          <Route path="/admin/stores" element={<StoresAdmin />} />
          
          {/* Dashboards */}
          <Route path="/dashboards/store" element={<StoreDashboard />} />
          <Route path="/dashboards/area" element={<AreaDashboard />} />
          <Route path="/dashboards/national" element={<NationalDashboard />} />

          {/* HR */}
          <Route path="/hr/employees" element={<Employees />} />
          <Route path="/hr/pay-roll" element={<PayRoll />} />

          {/* Inventory */}
          <Route path="/inventory/racks" element={<Racks />} />
          <Route path="/inventory/stock" element={<Stock />} />
          <Route path="/inventory/stock-movement" element={<StockMovements />} />

          {/* Promotions */}
          <Route path="/promotions/coupons" element={<Coupons />} />
          <Route path="/promotions/discounts" element={<Discounts />} />

          {/* Purchases */}
          <Route path="/purchases/purchase-orders" element={<PurchaseOrders />} />
          <Route path="/purchases/suppliers" element={<Suppliers />} />


        </Route>

        {/* Rutas que NO UTILIZAN NINGUN LAYOUT y que NECESITAN una SESIÓN ACTIVA */}
        <Route path="/pos" element={<POS />} />
        
      </Route>

      {/* RUTA COMODÍN: Redirección por defecto ante rutas inexistentes */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

export default AppRoutes;