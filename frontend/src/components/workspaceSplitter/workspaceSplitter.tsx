import type { ReactNode } from 'react';
import { Splitter } from '@mantine/core';
import { useViewportType } from '../../hooks/useViewportType';
import './workspaceSplitter.css';

// Define la configuración individual de cada panel dentro del splitter.
export interface SplitterPaneConfig {
  paneId: string;
  paneContent: ReactNode;
  defaultSize?: number;
  minSize?: number;
  maxSize?: number;
  isScrollable?: boolean;
  hasPadding?: boolean;
}

// Define las propiedades principales del componente contenedor de paneles divididos.
export interface WorkspaceSplitterProps {
  paneItems: SplitterPaneConfig[];
  splitOrientation?: 'horizontal' | 'vertical';
  keepOrientationOnMobile?: boolean;
  layoutVariant?: 'full' | 'nested';
  extraClassName?: string;
}

// Renderiza un contenedor con paneles redimensionables para gráficos, tablas o métricas.
function WorkspaceSplitter({
  paneItems,
  splitOrientation = 'horizontal',
  keepOrientationOnMobile = false,
  layoutVariant = 'full',
  extraClassName = '',
}: WorkspaceSplitterProps) {
  // Obtiene el tipo de pantalla actual para adaptar la disposición en móviles.
  const currentViewport = useViewportType();

  // Cambia a orientación vertical en móviles salvo que se fuerce mantener la original.
  const resolvedOrientation =
    currentViewport === 'mobile' && !keepOrientationOnMobile ? 'vertical' : splitOrientation;

  // Construye las clases CSS del contenedor principal según variante, orientación y extras.
  const rootClassNames = [
    'pedestalSplitter',
    `pedestalSplitter--${layoutVariant}`,
    `pedestalSplitter--${resolvedOrientation}`,
    extraClassName,
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <Splitter
      orientation={resolvedOrientation}
      className={rootClassNames}
      classNames={{
        root: 'pedestalSplitterRoot',
        handle: 'pedestalSplitterHandle',
      }}
    >
      {/* Recorre los paneles configurados y aplica scroll, padding y tamaños por defecto. */}
      {paneItems.map((pane) => {
        const paneClassNames = [
          'pedestalSplitterPane',
          pane.isScrollable !== false ? 'pedestalSplitterPane--scrollable' : '',
          pane.hasPadding !== false ? 'pedestalSplitterPane--padded' : '',
        ]
          .filter(Boolean)
          .join(' ');

        return (
          <Splitter.Pane
            key={pane.paneId}
            defaultSize={pane.defaultSize ?? 50}
            min={pane.minSize ?? 20}
            max={pane.maxSize}
            className={paneClassNames}
          >
            {pane.paneContent}
          </Splitter.Pane>
        );
      })}
    </Splitter>
  );
}

export default WorkspaceSplitter;