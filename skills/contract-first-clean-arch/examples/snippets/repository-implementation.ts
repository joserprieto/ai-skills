// LANGUAGE-AGNOSTIC PATTERN: Repository Implementation (Port Adapter)
// TypeScript as notation. Python: concrete class extending ABC. Go: struct.
//
// Key rules:
//  - Implements the port interface defined in domain/ports/.
//  - In-memory version = Fake for tests (zero I/O, deterministic).
//  - SQL version = production adapter (translates domain ↔ rows).
//  - The Criteria is translated to SQL WHERE clauses by the adapter.
//  - Domain NEVER knows which implementation is running.
//  - Both implementations MUST handle ALL Criteria fields — not a subset.

// --- Fake: in-memory (lives in infrastructure/ or test/) ---

class InMemoryOrderRepository implements OrderRepository {
  private store = new Map<string, Order>();

  async find(id: OrderId): Promise<Order | null> {
    return this.store.get(id.toString()) ?? null;
  }

  async search(criteria: OrderSearchCriteria): Promise<Order[]> {
    // Every Criteria field must be handled. Skipping fields silently
    // changes search semantics between in-memory and SQL implementations.
    return Array.from(this.store.values()).filter((order) => {
      if (criteria.status && order.status !== criteria.status) return false;
      if (criteria.buyerEmail && order.buyerEmail !== criteria.buyerEmail) return false;
      if (criteria.createdAfter && order.createdAt < criteria.createdAfter) return false;
      if (criteria.createdBefore && order.createdAt > criteria.createdBefore) return false;
      if (criteria.eventId && order.eventId !== criteria.eventId) return false;
      return true;
    });
  }

  async save(order: Order): Promise<void> {
    this.store.set(order.id.toString(), order);
  }

  clear(): void {
    this.store.clear();
  } // test helper
}

// --- Production: SQL (lives in infrastructure/) ---
// Criteria → WHERE clause translation happens HERE, not in domain.

class PostgresOrderRepository implements OrderRepository {
  constructor(private pool: Pool) {}

  async find(id: OrderId): Promise<Order | null> {
    const result = await this.pool.query('SELECT * FROM orders WHERE id = $1', [id.toString()]);
    return result.rows[0]
      ? Order.fromPersistence(
          OrderId.fromString(result.rows[0].id),
          result.rows[0].status,
          result.rows[0].event_id,
          result.rows[0].buyer_email,
          Money.create(result.rows[0].total_amount, result.rows[0].currency),
          new Date(result.rows[0].created_at)
        )
      : null;
  }

  async search(criteria: OrderSearchCriteria): Promise<Order[]> {
    const conditions: string[] = [];
    const params: unknown[] = [];
    if (criteria.status) {
      conditions.push(`status = $${params.push(criteria.status)}`);
    }
    if (criteria.buyerEmail) {
      conditions.push(`buyer_email = $${params.push(criteria.buyerEmail)}`);
    }
    if (criteria.createdAfter) {
      conditions.push(`created_at >= $${params.push(criteria.createdAfter)}`);
    }
    if (criteria.createdBefore) {
      conditions.push(`created_at <= $${params.push(criteria.createdBefore)}`);
    }
    if (criteria.eventId) {
      conditions.push(`event_id = $${params.push(criteria.eventId)}`);
    }
    const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    const result = await this.pool.query(`SELECT * FROM orders ${where}`, params);
    return result.rows.map((row) =>
      Order.fromPersistence(
        OrderId.fromString(row.id),
        row.status,
        row.event_id,
        row.buyer_email,
        Money.create(row.total_amount, row.currency),
        new Date(row.created_at)
      )
    );
  }

  async save(order: Order): Promise<void> {
    await this.pool.query(
      `INSERT INTO orders (id, status, event_id, buyer_email, total_amount, currency, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       ON CONFLICT (id) DO UPDATE SET status = $2, buyer_email = $4, total_amount = $5, currency = $6`,
      [
        order.id.toString(),
        order.status,
        order.eventId,
        order.buyerEmail,
        order.totalAmount.amount,
        order.totalAmount.currency,
        order.createdAt,
      ]
    );
  }
}
