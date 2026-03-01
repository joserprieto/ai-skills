// LANGUAGE-AGNOSTIC PATTERN: Entity with State Machine
// TypeScript as notation. Python: class with methods. Go: struct with methods.
//
// Key rules:
//  - Guards reject invalid transitions BEFORE mutating state.
//  - Domain events are recorded, not dispatched — the caller pulls them.
//  - The entity owns its invariants; no external code sets _status directly.

type OrderStatus = 'pending' | 'confirmed' | 'paid' | 'cancelled' | 'refunded';

class Order {
  private events: DomainEvent[] = [];

  private constructor(
    readonly id: OrderId,
    private _status: OrderStatus,
    readonly eventId: string,
    readonly buyerEmail: string,
    private readonly _totalAmount: Money,
    readonly createdAt: Date
  ) {}

  // Read-only accessors exist for persistence mapping and test assertions.
  // Tell Don't Ask targets callers making decisions based on state —
  // e.g., `if (order.status === 'pending') order.confirm()` is BAD.
  // The entity guards its own transitions; the caller just tells.
  get status(): OrderStatus {
    return this._status;
  }
  get totalAmount(): Money {
    return this._totalAmount;
  }

  static create(id: OrderId, eventId: string, buyerEmail: string, totalAmount: Money): Order {
    const order = new Order(id, 'pending', eventId, buyerEmail, totalAmount, new Date());
    order.record('OrderCreated', { buyerEmail });
    return order;
  }

  // Reconstitutes from persistence — bypasses events (already persisted).
  static fromPersistence(
    id: OrderId, status: OrderStatus, eventId: string, email: string, amount: Money, createdAt: Date
  ): Order {
    return new Order(id, status, eventId, email, amount, createdAt);
  }

  confirm(): void {
    if (this._status !== 'pending') throw new OrderNotPendingError(this.id);
    this._status = 'confirmed';
    this.record('OrderConfirmed', {});
  }

  pay(paymentId: string): void {
    if (this._status !== 'confirmed') throw new OrderNotConfirmedError(this.id);
    this._status = 'paid';
    this.record('OrderPaid', { paymentId });
  }

  cancel(reason: string): void {
    if (this._status === 'paid') throw new PaidOrderCannotBeCancelledError(this.id);
    if (this._status === 'refunded') throw new RefundedOrderCannotBeCancelledError(this.id);
    if (this._status === 'cancelled') throw new OrderAlreadyCancelledError(this.id);
    this._status = 'cancelled';
    this.record('OrderCancelled', { reason });
  }

  refund(reason: string): void {
    if (this._status !== 'paid') throw new OrderNotPaidError(this.id);
    this._status = 'refunded';
    this.record('OrderRefunded', { reason });
  }

  pullDomainEvents(): DomainEvent[] {
    const pulled = [...this.events];
    this.events = [];
    return pulled;
  }

  private record(type: string, payload: Record<string, unknown>): void {
    this.events.push({ type, aggregateId: this.id.toString(), occurredAt: new Date(), payload });
  }
}
