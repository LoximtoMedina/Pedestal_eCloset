// Importación de los hooks de react para manejar el estado local y efectos secundarios
import { useState, useEffect } from 'react';

// Definición de los tres posibles tipos de pantalla que puede devolver el hook
export type ViewportType = 'mobile' | 'tablet' | 'desktop';

// Definición de la interfaz opcional para personalizar los anchos máximos de móvil y tablet
interface Breakpoints {
  mobileMax?: number; // Límite superior en píxeles para considerar 'mobile' (por defecto 768)
  tabletMax?: number; // Límite superior en píxeles para considerar 'tablet' (por defecto 1024)
}

// Declaración del custom hook recibiendo un objeto de breakpoints con valores por defecto
export function useViewportType({
  mobileMax = 768,
  tabletMax = 1024,
}: Breakpoints = {}): ViewportType {
  // Función auxiliar que evalúa el tamaño actual y devuelve 'mobile', 'tablet' o 'desktop'
  const getViewportType = (): ViewportType => {
    // Evita errores si el código se ejecuta en un entorno sin objeto window (ej. SSR)
    if (typeof window === 'undefined') return 'desktop';

    // Crea una media query para detectar pantallas hasta mobileMax (ej. <= 768px)
    const mobileQuery = window.matchMedia(`(max-width: ${mobileMax}px)`);
    // Si la media query coincide actualmente, retorna 'mobile'
    if (mobileQuery.matches) return 'mobile';

    // Crea una media query para el rango intermedio de tablet (ej. 769px a 1024px)
    const tabletQuery = window.matchMedia(
      `(min-width: ${mobileMax + 1}px) and (max-width: ${tabletMax}px)`
    );
    // Si coincide con el rango de tablet, retorna 'tablet'
    if (tabletQuery.matches) return 'tablet';

    // Si no es ni móvil ni tablet, asume pantalla de escritorio ('desktop')
    return 'desktop';
  };

  // Inicializa el estado con el tipo de pantalla detectado al montar el componente
  const [viewport, setViewport] = useState<ViewportType>(getViewportType);

  // Configura los oyentes de cambio de media query y su limpieza al desmontar
  useEffect(() => {
    // Sale del efecto si no existe window
    if (typeof window === 'undefined') return;

    // Instancia la media query de móvil con el breakpoint actual
    const mobileQuery = window.matchMedia(`(max-width: ${mobileMax}px)`);
    // Instancia la media query de tablet con el rango actual
    const tabletQuery = window.matchMedia(
      `(min-width: ${mobileMax + 1}px) and (max-width: ${tabletMax}px)`
    );

    // Función que recalcula y actualiza el estado cuando se cruza un umbral
    const updateViewport = () => {
      setViewport(getViewportType());
    };

    // Sincroniza el estado por si el tamaño cambió justo antes de montar el efecto
    updateViewport();

    // Escucha cambios cuando se entra o sale del rango de móvil
    mobileQuery.addEventListener('change', updateViewport);
    // Escucha cambios cuando se entra o sale del rango de tablet
    tabletQuery.addEventListener('change', updateViewport);

    // Función de limpieza: elimina los listeners cuando cambian dependencias o se desmonta
    return () => {
      mobileQuery.removeEventListener('change', updateViewport);
      tabletQuery.removeEventListener('change', updateViewport);
    };
    // Vuelve a suscribirse solo si cambian mobileMax o tabletMax
  }, [mobileMax, tabletMax]);

  // Devuelve el tipo de viewport actual ('mobile' | 'tablet' | 'desktop')
  return viewport;
}