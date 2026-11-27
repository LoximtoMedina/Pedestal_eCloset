import {
  IconBuildingStore,
  IconChartBar,
  IconGauge,
  IconPackage,
} from '@tabler/icons-react';
import { Badge, Group, Progress, Table, Text, Title } from '@mantine/core';
import type { SideBarSection } from '../../../components/sideBar/sideBar';
import WorkspaceSplitter, {
  type SplitterPaneConfig,
} from '../../../components/workspaceSplitter/workspaceSplitter';
import { useLayoutNavItems } from '../../../hooks/useLayoutNavItems';
import './areaDashboard.css';

// Define la estructura de cada fila en la tabla de rendimiento por tienda.
interface StorePerformanceRow {
  storeId: string;
  storeName: string;
  monthlySales: string;
  goalCompletion: number;
  stockStatus: 'Óptimo' | 'Bajo' | 'Crítico';
}

// Datos simulados para visualizar el comportamiento del dashboard de área.
const areaStoresData: StorePerformanceRow[] = [
  {
    storeId: 'ST-01',
    storeName: 'Tienda Centro',
    monthlySales: '$42,800',
    goalCompletion: 92,
    stockStatus: 'Óptimo',
  },
  {
    storeId: 'ST-02',
    storeName: 'Tienda Plaza Norte',
    monthlySales: '$36,150',
    goalCompletion: 78,
    stockStatus: 'Bajo',
  },
  {
    storeId: 'ST-03',
    storeName: 'Tienda Galerías',
    monthlySales: '$29,400',
    goalCompletion: 64,
    stockStatus: 'Crítico',
  },
];

// Define las secciones de navegación que la vista inyecta en la barra lateral.
const dashboardSideBarSections: SideBarSection[] = [
  {
    label: 'Resumen General',
    icon: IconGauge,
    link: '/dashboards',
  },
  {
    label: 'Dashboards',
    icon: IconChartBar,
    initiallyOpened: true,
    links: [
      { label: 'Tienda', link: '/dashboards/store' },
      { label: 'Área', link: '/dashboards/area' },
      { label: 'Nacional', link: '/dashboards/national' },
    ],
  },
  {
    label: 'Inventario',
    icon: IconPackage,
    link: '/inventory',
  },
  {
    label: 'Punto de Venta',
    icon: IconBuildingStore,
    link: '/pos',
  },
];

// Renderiza la vista de Dashboard de Área utilizando contenedores divididos redimensionables.
function AreaDashboard() {
  // Sincroniza los enlaces de navegación de esta vista con el DashboardLayout padre.
  useLayoutNavItems(dashboardSideBarSections);

  // Configura los paneles secundarios (apilados verticalmente) de la columna derecha.
  const secondaryPaneItems: SplitterPaneConfig[] = [
    {
      paneId: 'area-kpi-summary',
      defaultSize: 45,
      minSize: 25,
      paneContent: (
        <div className="dashboardPaneSection">
          <Group justify="space-between" mb="xs">
            <Title order={4}>Meta Mensual del Área</Title>
            <Badge color="teal" variant="light">
              84% alcanzado
            </Badge>
          </Group>
          <Text size="sm" c="dimmed" mb="md">
            Acumulado de ventas frente al objetivo proyectado para el trimestre.
          </Text>
          <Progress value={84} size="lg" radius="md" color="teal" />
        </div>
      ),
    },
    {
      paneId: 'area-stock-alerts',
      defaultSize: 55,
      minSize: 25,
      paneContent: (
        <div className="dashboardPaneSection">
          <Title order={4} mb="xs">
            Alertas de Reposición
          </Title>
          <Text size="sm" c="dimmed" mb="sm">
            Sucursales que requieren transferencia interna de mercancía.
          </Text>
          <div className="dashboardAlertCard">
            <Text size="sm" fw={600}>
              Tienda Galerías — Línea Casual
            </Text>
            <Text size="xs" c="dimmed">
              Stock por debajo del 15% mínimo configurado.
            </Text>
          </div>
        </div>
      ),
    },
  ];

  // Configura los paneles principales (lado a lado) del espacio de trabajo.
  const primaryPaneItems: SplitterPaneConfig[] = [
    {
      paneId: 'area-sales-overview',
      defaultSize: 62,
      minSize: 35,
      paneContent: (
        <div className="dashboardPaneSection">
          <Group justify="space-between" mb="md">
            <div>
              <Title order={3}>Rendimiento por Tienda — Área Norte</Title>
              <Text size="sm" c="dimmed">
                Arrastra el separador central para ajustar el ancho de los paneles.
              </Text>
            </div>
            <Badge variant="outline" color="dark">
              Noviembre 2026
            </Badge>
          </Group>

          {/* Espacio reservado para insertar tu gráfica de @mantine/charts */}
          <div className="dashboardChartPlaceholder">
            <Text size="sm" c="dimmed">
              Contenedor de Gráfico Comparativo de Ventas
            </Text>
          </div>

          <Table striped highlightOnHover mt="md">
            <Table.Thead>
              <Table.Tr>
                <Table.Th>Tienda</Table.Th>
                <Table.Th>Ventas</Table.Th>
                <Table.Th>Cumplimiento</Table.Th>
                <Table.Th>Inventario</Table.Th>
              </Table.Tr>
            </Table.Thead>
            <Table.Tbody>
              {areaStoresData.map((storeRow) => (
                <Table.Tr key={storeRow.storeId}>
                  <Table.Td>{storeRow.storeName}</Table.Td>
                  <Table.Td>{storeRow.monthlySales}</Table.Td>
                  <Table.Td>{storeRow.goalCompletion}%</Table.Td>
                  <Table.Td>
                    <Badge
                      color={
                        storeRow.stockStatus === 'Óptimo'
                          ? 'teal'
                          : storeRow.stockStatus === 'Bajo'
                            ? 'yellow'
                            : 'red'
                      }
                      variant="light"
                    >
                      {storeRow.stockStatus}
                    </Badge>
                  </Table.Td>
                </Table.Tr>
              ))}
            </Table.Tbody>
          </Table>
        </div>
      ),
    },
    {
      paneId: 'area-right-column',
      defaultSize: 38,
      minSize: 25,
      hasPadding: false,
      isScrollable: false,
      paneContent: (
        <WorkspaceSplitter
          layoutVariant="nested"
          splitOrientation="vertical"
          paneItems={secondaryPaneItems}
        />
      ),
    },
  ];

  return (
    <section className="areaDashboardContainer">
      <WorkspaceSplitter
        layoutVariant="full"
        splitOrientation="horizontal"
        paneItems={primaryPaneItems}
      />
    </section>
  );
}

export default AreaDashboard;