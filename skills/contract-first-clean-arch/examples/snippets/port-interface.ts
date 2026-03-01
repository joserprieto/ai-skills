// LANGUAGE-AGNOSTIC PATTERN: Port Interface with Criteria
// TypeScript as notation. Python: ABC + @abstractmethod. Go: interface.
//
// Key rules:
//  - Ports live in domain/ports/ — they define WHAT, never HOW.
//  - Infrastructure implements ports — dependency points INWARD.
//  - Search uses Criteria pattern: a domain value object for composable filters.
//    NEVER add find_by_city(), find_by_capacity() etc. — combinatorial explosion.
//  - Adding a new filter = adding a field to Criteria, NOT changing the port.

// --- Criteria as domain value object ---

interface OrderSearchCriteria {
  buyerEmail?: string;
  status?: 'pending' | 'confirmed' | 'paid' | 'cancelled' | 'refunded';
  createdAfter?: Date;
  createdBefore?: Date;
  eventId?: string;
}

// --- Port: persistence ---

interface OrderRepository {
  find(id: OrderId): Promise<Order | null>;
  search(criteria: OrderSearchCriteria): Promise<Order[]>;
  save(order: Order): Promise<void>;
}

// --- Port: external service ---

interface PaymentGateway {
  charge(amount: Money, token: string): Promise<{ paymentId: string }>;
  refund(paymentId: string): Promise<void>;
}
