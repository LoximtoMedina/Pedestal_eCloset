import { useEffect } from 'react';
import { useOutletContext } from 'react-router';
import type { HeaderNavItem } from '../components/header/header';

export interface PublicLayoutOutletContext {
  setHeaderItems: (items: HeaderNavItem[]) => void;
}

export function usePublicHeaderItems(items: HeaderNavItem[]) {
  const context = useOutletContext<PublicLayoutOutletContext | undefined>();

  useEffect(() => {
    context?.setHeaderItems(items);
    return () => context?.setHeaderItems([]);
  }, [context, items]);
}