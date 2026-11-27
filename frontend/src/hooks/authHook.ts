import { useContext } from 'react';
import {
  AuthContext,
  type AuthContextValue,
} from '../context/authContextInstance';

export function getDashboardRoute(
  role?: string,
  initialRoute?: string
): string {
  if (initialRoute) {
    return initialRoute;
  }

  switch (role) {
    case 'Admin':
    case 'admin':
      return '/admin/roles';
    case 'NationalManager':
    case 'national_manager':
    case 'jefe_nacional':
      return '/dashboards/national';
    case 'AreaManager':
    case 'area_manager':
    case 'jefe_area':
      return '/dashboards/area';
    case 'StoreSupervisor':
    case 'Staff':
    case 'store_manager':
    case 'jefe_tienda':
      return '/pos';
    case 'Customer':
    default:
      return '/shop/catalog';
  }
}

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth debe usarse dentro de un AuthProvider');
  }
  return context;
}