// LANGUAGE-AGNOSTIC PATTERN: Object Mother with Faker
// TypeScript as notation. Python: class methods + faker. Go: helper funcs.
//
// Key rules:
//  - Semantic factory names: pending(), paid(), cancelled() — NOT create_test_order().
//  - Faker generates IRRELEVANT fields (email, name). The Mother fixes RELEVANT ones (status).
//  - The test reads: "given a paid order" — intention is obvious.
//  - Each method returns a VALID domain entity — it goes through the real constructor.

import { faker } from '@faker-js/faker';

class OrderMother {
  static pending(): Order {
    return Order.create(
      OrderId.generate(),
      faker.string.uuid(),
      faker.internet.email(),
      Money.create(faker.number.float({ min: 10, max: 500, fractionDigits: 2 }), 'EUR'),
    );
  }

  static confirmed(): Order {
    const order = OrderMother.pending();
    order.confirm();
    return order;
  }

  static paid(): Order {
    const order = OrderMother.confirmed();
    order.pay(`pi_${faker.string.alphanumeric(24)}`);
    return order;
  }

  static cancelled(reason = 'Test cancellation'): Order {
    const order = OrderMother.pending();
    order.cancel(reason);
    return order;
  }

  static refunded(reason = 'Test refund'): Order {
    const order = OrderMother.paid();
    order.refund(reason);
    return order;
  }

  static withEmail(email: string): Order {
    return Order.create(
      OrderId.generate(),
      faker.string.uuid(),
      email,
      Money.create(100, 'EUR'),
    );
  }
}

// Test usage:
// const order = OrderMother.paid();
// expect(order.status).toBe('paid');
// expect(order.pullDomainEvents()).toHaveLength(3); // Created + Confirmed + Paid
