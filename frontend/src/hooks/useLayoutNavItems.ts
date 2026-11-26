import { useEffect } from 'react';
import { useOutletContext } from 'react-router';

export interface LayoutNavOutletContext<T> {
  setNavItems: (items: T[]) => void;
}

export function useLayoutNavItems<T>(items: T[]) {
  const context = useOutletContext<LayoutNavOutletContext<T> | undefined>();

  useEffect(() => {
    context?.setNavItems(items);
    return () => context?.setNavItems([]);
  }, [context, items]);
}