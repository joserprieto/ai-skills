// LANGUAGE-AGNOSTIC PATTERN: Immutable Value Object
// TypeScript as notation. Python: @dataclass(frozen=True). Go: struct (no setters).
//
// Key rules:
//  - All fields readonly — mutation returns a new instance.
//  - Self-validating: constructor rejects invalid state.
//  - Equality by value, not reference.
//  - No identity — two Money(100, 'EUR') are the same concept.

// Domain errors — never throw generic Error for business rule violations.
class NegativeAmountError extends DomainError {
  constructor(amount: number) {
    super(`Amount must be non-negative, got ${amount}`);
  }
}
class CurrencyMismatchError extends DomainError {
  constructor(a: string, b: string) {
    super(`Cannot combine ${a} with ${b}`);
  }
}

class Money {
  private constructor(
    readonly amount: number,
    readonly currency: 'EUR' | 'USD' | 'GBP'
  ) {}

  static create(amount: number, currency: 'EUR' | 'USD' | 'GBP'): Money {
    if (amount < 0) throw new NegativeAmountError(amount);
    return new Money(amount, currency);
  }

  add(other: Money): Money {
    if (this.currency !== other.currency) {
      throw new CurrencyMismatchError(this.currency, other.currency);
    }
    return Money.create(this.amount + other.amount, this.currency);
  }

  equals(other: Money): boolean {
    return this.amount === other.amount && this.currency === other.currency;
  }
}

// Typed identifier — prevents mixing OrderId with EventId at compile time.
class OrderId {
  private constructor(readonly value: string) {}
  static generate(): OrderId {
    return new OrderId(crypto.randomUUID());
  }
  static fromString(raw: string): OrderId {
    return new OrderId(raw);
  }
  toString(): string {
    return this.value;
  }
}
