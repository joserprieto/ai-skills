// REACT-SPECIFIC PATTERN: Store Factory with Dependency Injection
// This snippet IS framework-specific (React + Zustand). The DI principle
// transfers to other frameworks, but the implementation does not.
//
// Key rules:
//  - Store is created via factory that receives port interfaces.
//  - Store calls ports — NEVER calls fetch() directly.
//  - Components consume the store — NEVER import from infrastructure/.
//  - Tests inject fake ports into the factory — no HTTP mocking needed.

import { create } from 'zustand';

// Domain type (defined in domain/types/, NOT in this file).
// Named TicketingEvent to avoid shadowing the browser DOM Event global.
interface TicketingEvent {
  id: string;
  title: string;
  startsAt: string;
}

// Port interface (lives in domain/ports/, NOT in this file)
interface EventSearchCriteria {
  query?: string;
  dateFrom?: string;
}

interface EventRepository {
  find(id: string): Promise<TicketingEvent | null>;
  search(criteria: EventSearchCriteria): Promise<TicketingEvent[]>;
}

// Factory: receives ports, returns a typed hook
function createEventStore(eventRepo: EventRepository) {
  return create<{
    events: TicketingEvent[];
    loading: boolean;
    search: (query: string) => Promise<void>;
  }>((set) => ({
    events: [],
    loading: false,
    search: async (query: string) => {
      set({ loading: true });
      const events = await eventRepo.search({ query });
      set({ events, loading: false });
    },
  }));
}

// Production: const useEventStore = createEventStore(new ApiEventRepository());
// Test:       const useEventStore = createEventStore(fakeEventRepo);
