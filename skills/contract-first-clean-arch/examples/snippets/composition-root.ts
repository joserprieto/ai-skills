// LANGUAGE-AGNOSTIC PATTERN: Composition Root
// TypeScript as notation. Python: FastAPI Depends(). Go: main() wiring.
//
// Key rules:
//  - The ONLY file that imports concrete infrastructure implementations.
//  - Wires every port to its adapter — domain never knows which adapter runs.
//  - Overrides mechanism allows tests to inject in-memory doubles.
//  - No business logic lives here — only wiring.

import { PostgresOrderRepository } from './booking/infrastructure/postgres-order-repository';
import { StripePaymentGateway } from './booking/infrastructure/stripe-payment-gateway';
import { InMemoryEventBus } from './shared/infrastructure/in-memory-event-bus';
import { PurchaseOrder } from './booking/application/purchase-order';

interface Overrides {
  orders?: OrderRepository;
  payments?: PaymentGateway;
  events?: EventBus;
}

function buildApp(overrides: Overrides = {}) {
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });

  // Every port gets a default production adapter, overridable for tests.
  const orders = overrides.orders ?? new PostgresOrderRepository(pool);
  const payments = overrides.payments ?? new StripePaymentGateway(process.env.STRIPE_KEY!);
  const events = overrides.events ?? new InMemoryEventBus();

  const purchaseOrder = new PurchaseOrder(orders, payments, events);

  // Register routes, start server, etc.
  return { purchaseOrder };
}

// Test usage:
// const app = buildApp({ orders: new InMemoryOrderRepository(), payments: new StubPaymentGateway() });
