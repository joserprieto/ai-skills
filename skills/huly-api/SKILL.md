---
name: huly-api
description: >
  Interact with Huly project management platform via its TypeScript/WebSocket API. Create and manage
  issues, milestones, components, documents, and attachments programmatically. Use when syncing work
  between local project state and Huly tracker/wiki. Handles auth, class IDs, gotchas, and content
  upload (markdown, files). Covers both Cloud and self-hosted instances.
metadata:
  author: Jose R. Prieto (hi [at] joserprieto [dot] es)
  version: '0.1.0'
  huly_api_client_version: '0.7.413'
---

# Skill: Huly Platform API

Programmatic access to Huly (project management, wiki, tracker) via the `@hcengineering/api-client`
TypeScript library. WebSocket-based, NOT REST.

## When to use this skill

- Creating/updating issues, milestones, components in Huly Tracker
- Creating/updating documents in Huly Wiki
- Syncing project state between local files and Huly
- Reading project status from Huly for reporting
- Attaching files (drawio, images, PDFs) to issues or documents
- Configuring project structure (statuses, labels, task types)

## Prerequisites

### Credentials

Stored in `~/.ai/secrets/huly-saas.env`:

```env
HULY_EMAIL=<your-huly-email>
HULY_PASSWORD=password
HULY_URL=https://huly.app
HULY_WORKSPACE=workspace-slug
```

Load with: `require('dotenv').config({ path: '/path/to/.ai/secrets/huly-saas.env' })`

### npm packages

```json
{
  "@hcengineering/api-client": "0.7.413",
  "@hcengineering/core": "0.7.413",
  "@hcengineering/rank": "0.7.413",
  "ws": "^8.16.0",
  "dotenv": "^16.4.0"
}
```

**CRITICAL**: Use exact version `0.7.413`. The `@hcengineering/tracker` and
`@hcengineering/document` packages have broken transitive dependencies — do NOT install them. Use
string class IDs instead.

## Connection

### Preferred: API token (no credentials exposed)

Generate token in Huly: Settings → General → API access → "Generate API token".

```javascript
const { connect } = require('@hcengineering/api-client');
const { generateId, SortingOrder } = require('@hcengineering/core');
const { makeRank } = require('@hcengineering/rank');
require('dotenv').config({ path: process.env.HULY_ENV_PATH || '~/.ai/secrets/huly-saas.env' });

const client = await connect(process.env.HULY_URL, {
  token: process.env.HULY_API_TOKEN,
  workspace: process.env.HULY_WORKSPACE,
  connectionTimeout: 30000,
});
// ... work ...
await client.close();
```

### Alternative: email + password (legacy, avoid)

```javascript
const client = await connect(process.env.HULY_URL, {
  email: process.env.HULY_EMAIL,
  password: process.env.HULY_PASSWORD,
  workspace: process.env.HULY_WORKSPACE,
  connectionTimeout: 30000,
});
```

**Ignore `no document found` warnings** — they're internal sync noise, not errors.

## Core concepts

### Class IDs (use strings, NOT imports)

```javascript
// Tracker
'tracker:class:Project';
'tracker:class:Issue';
'tracker:class:Milestone';
'tracker:class:Component';
'tracker:taskTypes:Issue'; // kind for issues

// Documents
'document:class:Teamspace';
'document:class:Document';

// Status values (NUMERIC for milestones, STRING refs for issues)
'tracker:status:Backlog'; // issue status
'tracker:status:Todo';
'tracker:status:InProgress';
'tracker:status:Done';
'tracker:status:Canceled';
0; // milestone status: planned (MUST be numeric!)

// Spaces
('core:space:Space'); // parent space for project operations
```

### createDoc vs addCollection

| Entity    | Method              | Why                       |
| --------- | ------------------- | ------------------------- |
| Milestone | `createDoc`         | Direct document           |
| Component | `createDoc`         | Direct document           |
| Document  | `createDoc`         | Direct document           |
| **Issue** | **`addCollection`** | Inherits from AttachedDoc |

```javascript
// Issues MUST use addCollection:
await client.addCollection(
  'tracker:class:Issue',
  projectId,
  projectId,
  'tracker:class:Project',
  'issues',
  { ...fields },
  issueId
);

// Everything else uses createDoc:
await client.createDoc('tracker:class:Milestone', projectId, { ...fields }, msId);
```

## References

- **Connection + auth** → `references/connection.md`
- **Issues (create, update, list, subtasks)** → `references/issues.md`
- **Documents (wiki, content upload)** → `references/documents.md`
- **Milestones + Components** → `references/structure.md`
- **Project configuration (statuses, labels)** → `references/project-config.md`
- **Attachments (files, images, drawio)** → `references/attachments.md`
- **Gotchas + known issues** → `references/gotchas.md`

## Source code references (the REAL documentation)

There is NO official API documentation. **The source code IS the documentation.**

| What               | Repository                               | Path                      |
| ------------------ | ---------------------------------------- | ------------------------- |
| **Platform core**  | `github.com/hcengineering/huly.core`     | —                         |
| **API client**     | same repo                                | `packages/api-client/`    |
| **RPC protocol**   | same repo                                | `packages/rpc/src/rpc.ts` |
| **Tracker model**  | same repo                                | `models/tracker/`         |
| **Document model** | same repo                                | `models/document/`        |
| **Card model**     | same repo                                | `models/card/`            |
| **API examples**   | `github.com/hcengineering/huly-examples` | `platform-api/examples/`  |

When in doubt about any API behavior, **read the source** — not the (nonexistent) docs.

## Custom classes via API

Card types (MasterTag) can be created programmatically using `core:space:Model` as the space:

```javascript
await client.createDoc(
  'card:class:MasterTag',
  'core:space:Model',
  {
    label: 'Domain Question',
    extends: 'card:class:Card',
    kind: 0,
  },
  generateId()
);
```

**CRITICAL**: regular spaces (`core:space:Space`) won't work for class creation. Must use
`core:space:Model`.

This enables: custom Card types per workspace (Domain Question, Business Rule, Domain Entity, etc.)
as reusable templates across client engagements.

## Critical gotchas (summary)

See `references/gotchas.md` for full details.

1. **Milestone status MUST be numeric** (`0` = planned). String `'planned'` silently fails.
2. **Issue status MUST be a tracker status ref** (`'tracker:status:Backlog'`). Empty string =
   invisible.
3. **Issues use `addCollection`**, not `createDoc`. Error: "cannot be used for AttachedDoc".
4. **Project type matters**: "Classic project" (`tracker:ids:ClassingProjectType`) has task types.
   Custom project types may have 0 task types → issues invisible in UI.
5. **DO NOT install `@hcengineering/tracker`** — broken transitive deps. Use string class IDs.
6. **Content upload**: use `client.uploadMarkup(class, id, 'content', markdown, 'markdown')` for
   rich document content. Plain string in `content` field won't render formatting.
7. **Sequence numbers**: increment with
   `client.updateDoc(Project, space, id, { $inc: { sequence: 1 } }, true)` and read from
   `result.object.sequence`.
8. **API has NO validation** — you can set `status: 'patata'` and it'll accept it silently. Always
   query valid values first.
