import { useMemo, useState } from 'react';
import {
  ActionIcon,
  Badge,
  Button,
  Divider,
  Drawer,
  Group,
  Modal,
  NumberInput,
  SegmentedControl,
  Select,
  Stack,
  Table,
  Text,
  TextInput,
  Title,
} from '@mantine/core';
import { useDisclosure } from '@mantine/hooks';
import { notifications } from '@mantine/notifications';
import {
  IconCheck,
  IconDiscount2,
  IconHistory,
  IconNote,
  IconPlus,
  IconReceipt,
  IconSearch,
  IconTrash,
  IconUser,
} from '@tabler/icons-react';
import { useViewportType } from '../../hooks/useViewportType';
import './posTerminal.css';

interface CustomerProfile {
  id: string;
  name: string;
  tier: string;
  storeCredit: number;
  points: number;
  visits: number;
}

interface PosProduct {
  id: string;
  code: string;
  name: string;
  category: string;
  size: string;
  price: number;
  image: string;
}

interface SaleItem {
  product: PosProduct;
  qty: number;
}

const customers: CustomerProfile[] = [
  {
    id: 'c-1',
    name: 'Valeria Mendoza',
    tier: 'Cliente eCloset',
    storeCredit: 0,
    points: 420,
    visits: 19,
  },
  {
    id: 'c-2',
    name: 'Sofía Castellanos',
    tier: 'VIP Pedestal',
    storeCredit: 250,
    points: 890,
    visits: 34,
  },
  {
    id: 'c-3',
    name: 'Mostrador General',
    tier: 'Cliente ocasional',
    storeCredit: 0,
    points: 0,
    visits: 1,
  },
];

const quickProducts: PosProduct[] = [
  {
    id: 'pr-1',
    code: '0013',
    name: 'Jeans Clásicos Rectos',
    category: 'Pantalones',
    size: 'M',
    price: 850,
    image:
      'https://images.unsplash.com/photo-1542272604-787c3835535d?auto=format&fit=crop&w=300&q=80',
  },
  {
    id: 'pr-2',
    code: '101',
    name: 'Vestido Largo Carmesí',
    category: 'Vestidos',
    size: 'S',
    price: 1250,
    image:
      'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=300&q=80',
  },
  {
    id: 'pr-3',
    code: '104',
    name: 'Camisa Lino Urbano',
    category: 'Camisas',
    size: 'M',
    price: 620,
    image:
      'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?auto=format&fit=crop&w=300&q=80',
  },
  {
    id: 'pr-4',
    code: '108',
    name: 'Top Básico Lima',
    category: 'Camisas',
    size: 'S',
    price: 420,
    image:
      'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=300&q=80',
  },
  {
    id: 'pr-5',
    code: '112',
    name: 'Falda Midi Arena',
    category: 'Vestidos',
    size: 'M',
    price: 940,
    image:
      'https://images.unsplash.com/photo-1583496661160-fb5886a0aaaa?auto=format&fit=crop&w=300&q=80',
  },
  {
    id: 'pr-6',
    code: '115',
    name: 'Pantalón Sastre Marfil',
    category: 'Pantalones',
    size: 'L',
    price: 790,
    image:
      'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=300&q=80',
  },
  {
    id: 'pr-7',
    code: '119',
    name: 'Jogger Entallado Negro',
    category: 'Pantalones',
    size: 'M',
    price: 740,
    image:
      'https://images.unsplash.com/photo-1552902865-b72c031ac5ea?auto=format&fit=crop&w=300&q=80',
  },
];

const TAX_RATE = 0.15;

function formatCurrency(value: number): string {
  return `L ${value.toLocaleString('es-HN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

function PosTerminal() {
  const viewport = useViewportType();
  const isCompact = viewport === 'mobile' || viewport === 'tablet';

  const [selectedCustomerId, setSelectedCustomerId] = useState<string>(customers[0].id);
  const [productQuery, setProductQuery] = useState('');
  const [activeCategory, setActiveCategory] = useState<string>('Todas');
  const [items, setItems] = useState<SaleItem[]>([
    { product: quickProducts[1], qty: 1 },
    { product: quickProducts[0], qty: 1 },
  ]);
  const [discountPct, setDiscountPct] = useState<number>(0);
  const [note, setNote] = useState<string>('');
  const [paymentMethod, setPaymentMethod] = useState<string>('Tarjeta');
  const [recentTickets, setRecentTickets] = useState<string[]>([]);

  const [payModalOpened, { open: openPayModal, close: closePayModal }] = useDisclosure(false);
  const [mobileTicketOpened, { open: openMobileTicket, close: closeMobileTicket }] =
    useDisclosure(false);

  const currentCustomer = useMemo(
    () => customers.find((c) => c.id === selectedCustomerId) ?? customers[0],
    [selectedCustomerId]
  );

  const categories = useMemo(
    () => ['Todas', ...Array.from(new Set(quickProducts.map((p) => p.category)))],
    []
  );

  const visibleProducts = useMemo(() => {
    const q = productQuery.trim().toLowerCase();
    return quickProducts.filter((item) => {
      const catMatch = activeCategory === 'Todas' || item.category === activeCategory;
      const searchMatch =
        q.length === 0 ||
        item.name.toLowerCase().includes(q) ||
        item.code.toLowerCase().includes(q);
      return catMatch && searchMatch;
    });
  }, [productQuery, activeCategory]);

  const handleAddProduct = (product: PosProduct) => {
    setItems((prev) => {
      const found = prev.find((row) => row.product.id === product.id);
      if (found) {
        return prev.map((row) =>
          row.product.id === product.id ? { ...row, qty: row.qty + 1 } : row
        );
      }
      return [...prev, { product, qty: 1 }];
    });
  };

  const handleRemoveRow = (productId: string) => {
    setItems((prev) => prev.filter((row) => row.product.id !== productId));
  };

  const handleNewSale = () => {
    setItems([]);
    setDiscountPct(0);
    setNote('');
  };

  const grossTotal = useMemo(
    () => items.reduce((acc, row) => acc + row.product.price * row.qty, 0),
    [items]
  );

  const discountValue = useMemo(
    () => (grossTotal * Math.min(Math.max(discountPct, 0), 100)) / 100,
    [grossTotal, discountPct]
  );

  const totalWithDiscount = Math.max(grossTotal - discountValue, 0);
  const netAmount = totalWithDiscount / (1 + TAX_RATE);
  const taxAmount = totalWithDiscount - netAmount;

  const confirmSale = () => {
    const code = `ECL-${Date.now().toString().slice(-5)}`;
    setRecentTickets((prev) => [code, ...prev.slice(0, 4)]);
    setItems([]);
    setDiscountPct(0);
    setNote('');
    closePayModal();
    closeMobileTicket();

    notifications.show({
      title: `Venta completada · ${code}`,
      message: `Cobrado ${formatCurrency(totalWithDiscount)} (${paymentMethod}).`,
      color: 'dark',
      icon: <IconCheck size={16} />,
    });
  };

  const leftTicketColumn = (
    <div className="pedestalPosLeftPanel">
      {/* Buscador de Cliente y Producto */}
      <div className="pedestalPosSearchRow">
        <Select
          aria-label="Seleccionar cliente"
          leftSection={<IconUser size={16} />}
          data={customers.map((c) => ({ value: c.id, label: c.name }))}
          value={selectedCustomerId}
          onChange={(val) => setSelectedCustomerId(val ?? customers[0].id)}
          searchable
          className="pedestalPosCustomerSelect"
        />

        <TextInput
          placeholder="Buscar producto o código"
          leftSection={<IconSearch size={16} />}
          value={productQuery}
          onChange={(e) => setProductQuery(e.currentTarget.value)}
          className="pedestalPosProductSearch"
        />
      </div>

      {/* Tarjeta de Cliente y Métricas */}
      <div className="pedestalPosCustomerCard">
        <div className="pedestalPosCustomerTop">
          <div className="pedestalPosAvatar">
            <IconUser size={26} stroke={1.6} />
          </div>
          <div>
            <Title order={4} className="pedestalPosCustomerName">
              {currentCustomer.name}
            </Title>
            <Text size="xs" c="dimmed">
              {currentCustomer.tier}
            </Text>
          </div>
        </div>

        <div className="pedestalPosCustomerStats">
          <div>
            <Text size="10px" fw={700} c="dimmed" className="pedestalPosStatLabel">
              SALDO
            </Text>
            <Text fw={700} size="sm">
              {formatCurrency(currentCustomer.storeCredit)}
            </Text>
          </div>
          <div>
            <Text size="10px" fw={700} c="dimmed" className="pedestalPosStatLabel">
              PUNTOS
            </Text>
            <Text fw={700} size="sm">
              {currentCustomer.points}
            </Text>
          </div>
          <div>
            <Text size="10px" fw={700} c="dimmed" className="pedestalPosStatLabel">
              VISITAS
            </Text>
            <Text fw={700} size="sm">
              {currentCustomer.visits}
            </Text>
          </div>
        </div>

        <div className="pedestalPosCustomerTabs">
          <Button variant="filled" size="xs" className="pedestalPosTabActive">
            Orden
          </Button>
          <Button variant="default" size="xs" className="pedestalPosTabNeutral">
            Historial
          </Button>
        </div>
      </div>

      {/* Tabla de artículos en la venta */}
      <div className="pedestalPosLinesWrapper">
        <Table verticalSpacing="xs" highlightOnHover className="pedestalPosLinesTable">
          <Table.Thead>
            <Table.Tr>
              <Table.Th>Prenda</Table.Th>
              <Table.Th>Código</Table.Th>
              <Table.Th ta="center">Cant.</Table.Th>
              <Table.Th ta="right">Precio</Table.Th>
              <Table.Th w={32} />
            </Table.Tr>
          </Table.Thead>
          <Table.Tbody>
            {items.length === 0 ? (
              <Table.Tr>
                <Table.Td colSpan={5}>
                  <Text size="xs" c="dimmed" ta="center" py="lg">
                    Sin prendas en la orden actual
                  </Text>
                </Table.Td>
              </Table.Tr>
            ) : (
              items.map((row) => (
                <Table.Tr key={row.product.id}>
                  <Table.Td>
                    <Text size="xs" fw={600} lineClamp={1}>
                      {row.product.name}
                    </Text>
                  </Table.Td>
                  <Table.Td>
                    <Text size="xs" c="dimmed">
                      {row.product.code}
                    </Text>
                  </Table.Td>
                  <Table.Td ta="center">
                    <Text size="xs" fw={600}>
                      {row.qty}
                    </Text>
                  </Table.Td>
                  <Table.Td ta="right">
                    <Text size="xs" fw={700}>
                      {formatCurrency(row.product.price * row.qty)}
                    </Text>
                  </Table.Td>
                  <Table.Td>
                    <ActionIcon
                      size="xs"
                      variant="subtle"
                      color="red"
                      aria-label="Quitar artículo"
                      onClick={() => handleRemoveRow(row.product.id)}
                    >
                      <IconTrash size={13} />
                    </ActionIcon>
                  </Table.Td>
                </Table.Tr>
              ))
            )}
          </Table.Tbody>
        </Table>
      </div>

      {note && (
        <Text size="xs" c="dimmed" mt="xs">
          Nota: {note}
        </Text>
      )}

      {/* Totales inferiores */}
      <div className="pedestalPosSummaryBox">
        <Group justify="space-between" align="baseline">
          <Text fw={800} size="lg" className="pedestalPosTotalHeading">
            TOTAL
          </Text>
          <Text fw={800} size="xl" className="pedestalPosTotalValue">
            {formatCurrency(totalWithDiscount)}
          </Text>
        </Group>

        <Group justify="space-between" mt={6}>
          <Text size="xs" fw={600} c="dimmed">
            ISV ({Math.round(TAX_RATE * 100)}%)
          </Text>
          <Text size="xs" fw={600}>
            {formatCurrency(taxAmount)}
          </Text>
        </Group>

        <Group justify="space-between" mt={4}>
          <Text size="xs" fw={600} c="dimmed">
            NETO
          </Text>
          <Text size="xs" fw={600}>
            {formatCurrency(netAmount)}
          </Text>
        </Group>
      </div>
    </div>
  );

  const rightPadColumn = (
    <div className="pedestalPosRightPanel">
      {/* Categorías rápidas */}
      <div className="pedestalPosCategoryRow">
        <ActionIcon
          size="lg"
          radius="sm"
          aria-label="Nueva venta rápida"
          onClick={handleNewSale}
          className="pedestalPosLavenderTileBtn"
        >
          <IconPlus size={18} />
        </ActionIcon>

        {categories.map((cat) => (
          <button
            key={cat}
            type="button"
            onClick={() => setActiveCategory(cat)}
            className={`pedestalPosCategoryTile ${
              activeCategory === cat ? 'pedestalPosCategoryTile--active' : ''
            }`}
          >
            {cat}
          </button>
        ))}
      </div>

      {/* Cuadrícula de prendas visuales */}
      <div className="pedestalPosQuickGrid">
        {visibleProducts.map((product) => (
          <button
            key={product.id}
            type="button"
            onClick={() => handleAddProduct(product)}
            className="pedestalPosProductTile"
          >
            <img
              src={product.image}
              alt={product.name}
              className="pedestalPosProductImg"
            />
            <span className="pedestalPosProductPriceTag">
              {formatCurrency(product.price)}
            </span>
          </button>
        ))}
      </div>

      {/* Botonera operativa (estilo cuadrícula de funciones) */}
      <div className="pedestalPosActionsGrid">
        <button type="button" className="pedestalPosActionTile" onClick={handleNewSale}>
          <IconPlus size={18} />
          <span>Nueva venta</span>
        </button>

        <button
          type="button"
          className="pedestalPosActionTile"
          onClick={() => setDiscountPct((prev) => (prev === 10 ? 0 : 10))}
        >
          <IconDiscount2 size={18} />
          <span>{discountPct > 0 ? `Desc. ${discountPct}%` : 'Desc. 10%'}</span>
        </button>

        <button
          type="button"
          className="pedestalPosActionTile"
          onClick={() =>
            setNote((prev) =>
              prev ? '' : 'Empaque especial de regalo eCloset'
            )
          }
        >
          <IconNote size={18} />
          <span>{note ? 'Quitar nota' : 'Nota venta'}</span>
        </button>

        <button
          type="button"
          className="pedestalPosActionTile"
          onClick={() => {
            if (recentTickets.length > 0) {
              notifications.show({
                title: 'Último recibo',
                message: `Ticket registrado: ${recentTickets[0]}`,
                color: 'dark',
              });
            }
          }}
        >
          <IconHistory size={18} />
          <span>Último ticket</span>
        </button>
      </div>

      {/* Barra inferior: Limpiar venta + Pagar */}
      <div className="pedestalPosBottomBar">
        <button
          type="button"
          onClick={handleNewSale}
          className="pedestalPosCancelSaleBtn"
        >
          <IconTrash size={18} />
          <span>VENTA</span>
        </button>

        <button
          type="button"
          disabled={items.length === 0}
          onClick={openPayModal}
          className="pedestalPosPaySaleBtn"
        >
          PAGAR · {formatCurrency(totalWithDiscount)}
        </button>
      </div>
    </div>
  );

  return (
    <section className={`pedestalPosTerminalSection pedestalPosTerminalSection--${viewport}`}>
      {/* Barra superior oscura estilo POS */}
      <header className="pedestalPosTopHeader">
        <Group gap="sm">
          <Text fw={800} size="md" className="pedestalPosBrandMark">
            ECLOSET POS
          </Text>
          <Text size="xs" className="pedestalPosBranchSub">
            PEDESTAL · Mostrador Principal
          </Text>
        </Group>

        <Group gap="xs">
          {recentTickets.length > 0 && (
            <Badge variant="outline" color="gray" size="sm">
              Último: {recentTickets[0]}
            </Badge>
          )}
          {isCompact && (
            <Button
              size="xs"
              variant="white"
              color="dark"
              leftSection={<IconReceipt size={15} />}
              onClick={openMobileTicket}
            >
              Orden ({items.reduce((acc, r) => acc + r.qty, 0)})
            </Button>
          )}
        </Group>
      </header>

      <div className="pedestalPosMainSplit">
        {!isCompact && leftTicketColumn}
        {rightPadColumn}
      </div>

      {isCompact && (
        <Drawer
          opened={mobileTicketOpened}
          onClose={closeMobileTicket}
          title="Orden y Cliente"
          position="left"
          size="90%"
        >
          {leftTicketColumn}
        </Drawer>
      )}

      <Modal opened={payModalOpened} onClose={closePayModal} title="Confirmar cobro" centered>
        <Stack gap="md">
          <Text size="sm" c="dimmed">
            Cliente: <strong>{currentCustomer.name}</strong>
          </Text>

          <div>
            <Text size="xs" fw={600} mb={6}>
              Método de pago
            </Text>
            <SegmentedControl
              fullWidth
              value={paymentMethod}
              onChange={setPaymentMethod}
              data={['Tarjeta', 'Efectivo', 'Transferencia']}
            />
          </div>

          <Group justify="space-between">
            <Text size="sm">Descuento (%)</Text>
            <NumberInput
              w={95}
              min={0}
              max={100}
              value={discountPct}
              onChange={(val) => setDiscountPct(typeof val === 'number' ? val : 0)}
            />
          </Group>

          <Divider />

          <Group justify="space-between">
            <Text fw={700}>Total a cobrar</Text>
            <Text fw={800} size="lg">
              {formatCurrency(totalWithDiscount)}
            </Text>
          </Group>

          <Group justify="flex-end" mt="sm">
            <Button variant="default" onClick={closePayModal}>
              Cancelar
            </Button>
            <Button className="pedestalPosModalConfirmBtn" onClick={confirmSale}>
              Confirmar venta
            </Button>
          </Group>
        </Stack>
      </Modal>
    </section>
  );
}

export default PosTerminal;