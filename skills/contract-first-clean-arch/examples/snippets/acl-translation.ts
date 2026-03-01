// LANGUAGE-AGNOSTIC PATTERN: Anti-Corruption Layer with Criteria Translation
// TypeScript as notation. The ACL sits in infrastructure/ and implements a domain port.
//
// Key rules:
//  - Domain defines VenueSearchCriteria (value object) + VenueProvider (port).
//  - ACL translates: Criteria → external query params, external response → domain type.
//  - Domain NEVER sees the external API shape.
//  - Adding a new search filter = adding a field to Criteria, not changing the port.
//  - Every external response is validated before use (Principle 5).

// --- Domain side (in domain/) ---

interface Venue {
  id: string;
  name: string;
  capacity: number;
  address: string;
}

interface VenueSearchCriteria {
  city?: string;
  minCapacity?: number;
  country?: string;
}

interface VenueProvider {
  search(criteria: VenueSearchCriteria): Promise<Venue[]>;
  find(id: string): Promise<Venue | null>;
}

// --- Infrastructure side (in infrastructure/external/) ---
// Named by technology + domain role: Ticketmaster (tech) + VenueProvider (role).

class TicketmasterVenueProvider implements VenueProvider {
  constructor(private baseUrl: string) {}

  async search(criteria: VenueSearchCriteria): Promise<Venue[]> {
    // 1. Translate domain Criteria → external API query params
    const params = new URLSearchParams();
    if (criteria.city) params.set('city', criteria.city);
    if (criteria.minCapacity) params.set('min_seats', String(criteria.minCapacity));
    if (criteria.country) params.set('country_iso', criteria.country);

    // 2. Call external API + validate response (Principle 5: untrusted input)
    const response = await fetch(`${this.baseUrl}/venues?${params}`);
    if (!response.ok) throw new ExternalServiceError('Ticketmaster', response.status);
    const raw: unknown = await response.json();
    const data = this.validateSearchResponse(raw);

    // 3. Translate external shape → domain type
    return data.map(this.toDomain);
  }

  async find(id: string): Promise<Venue | null> {
    const response = await fetch(`${this.baseUrl}/venues/${id}`);
    if (response.status === 404) return null;
    if (!response.ok) throw new ExternalServiceError('Ticketmaster', response.status);
    const raw: unknown = await response.json();
    return this.toDomain(this.validateVenueResponse(raw));
  }

  // Validate external response shape — never trust third-party APIs.
  // In production, use a schema validator (zod, ajv). Shown inline for clarity.
  private validateSearchResponse(raw: unknown): Record<string, unknown>[] {
    if (!Array.isArray(raw))
      throw new ExternalResponseInvalidError('Ticketmaster', 'expected array');
    return raw.map((item, i) => {
      if (!item || typeof item !== 'object')
        throw new ExternalResponseInvalidError('Ticketmaster', `element [${i}]: expected object`);
      return item as Record<string, unknown>;
    });
  }

  private validateVenueResponse(raw: unknown): Record<string, unknown> {
    if (!raw || typeof raw !== 'object') {
      throw new ExternalResponseInvalidError('Ticketmaster', 'expected object');
    }
    return raw as Record<string, unknown>;
  }

  // External: { venue_id, venue_name, max_capacity, street_address }
  // Domain:   { id, name, capacity, address }
  private toDomain(raw: Record<string, unknown>): Venue {
    return {
      id: raw.venue_id as string,
      name: raw.venue_name as string,
      capacity: raw.max_capacity as number,
      address: raw.street_address as string,
    };
  }
}
