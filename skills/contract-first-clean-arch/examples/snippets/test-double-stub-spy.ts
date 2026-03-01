// LANGUAGE-AGNOSTIC PATTERN: Test Doubles (Stub + Spy)
// TypeScript as notation. Python: class extending ABC. Go: struct with fields.
//
// Key rules:
//  - Doubles implement the SAME port interface as production adapters.
//  - Stub: returns canned data, configurable success/failure.
//  - Spy: records calls for later assertion.
//  - Fake (in-memory repo): see repository-implementation.ts.
//  - NEVER mock the domain — only mock ports (infrastructure boundaries).

// --- Stub: configurable behavior ---

class StubPaymentGateway implements PaymentGateway {
  private shouldSucceed = true;

  willFail(): void {
    this.shouldSucceed = false;
  }

  async charge(amount: Money, token: string): Promise<{ paymentId: string }> {
    if (!this.shouldSucceed) throw new PaymentDeclinedError('stub: charge rejected');
    return { paymentId: `pi_stub_${token.slice(0, 8)}` };
  }

  async refund(_paymentId: string): Promise<void> {
    if (!this.shouldSucceed) throw new RefundFailedError('stub: refund rejected');
  }
}

// --- Spy: records interactions ---

class SpyEventBus implements EventBus {
  private published: DomainEvent[] = [];

  async publish(event: DomainEvent): Promise<void> {
    this.published.push(event);
  }

  getPublished(): ReadonlyArray<DomainEvent> {
    return [...this.published];
  }
  ofType(type: string): DomainEvent[] {
    return this.published.filter((e) => e.type === type);
  }
}
