// LANGUAGE-AGNOSTIC PATTERN: Application Service (Orchestration)
// TypeScript as notation. Python: class with async execute(). Go: func.
//
// Key rules:
//  - Receives ports via constructor injection — NEVER imports infrastructure.
//  - Orchestrates: load aggregate → call domain methods → persist → publish events.
//  - Contains NO business rules — those live in the entity.
//  - Input is a plain data structure; output is void or a domain result.

interface PurchaseOrderInput {
  orderId: string;
  paymentToken: string;
}

class PurchaseOrder {
  constructor(
    private readonly orders: OrderRepository,
    private readonly payments: PaymentGateway,
    private readonly events: EventBus
  ) {}

  async execute(input: PurchaseOrderInput): Promise<void> {
    const order = await this.orders.find(OrderId.fromString(input.orderId));
    if (!order) throw new OrderNotFoundError(input.orderId);

    order.confirm();

    const { paymentId } = await this.payments.charge(order.totalAmount, input.paymentToken);
    order.pay(paymentId);

    await this.orders.save(order);

    for (const event of order.pullDomainEvents()) {
      await this.events.publish(event);
    }
  }
}
