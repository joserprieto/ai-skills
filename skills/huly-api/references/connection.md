# Connection — Huly API Reference

## Setup

### Install dependencies

```bash
npm install @hcengineering/api-client@0.7.413 @hcengineering/core@0.7.413 \
  @hcengineering/rank@0.7.413 ws@^8.16.0 dotenv@^16.4.0
```

**DO NOT install**: `@hcengineering/tracker`, `@hcengineering/document`, `@hcengineering/contact`.
These have broken transitive dependencies. Use string class IDs instead. See gotcha G-005.

### Credentials

File: a path of your choice (e.g. `~/.config/huly/credentials.env`), referenced via the
`HULY_ENV_PATH` env var. Keep it outside the repo, gitignored, with restricted permissions.

```env
HULY_EMAIL=<your-huly-email>
HULY_PASSWORD=password
HULY_URL=https://huly.app
HULY_WORKSPACE=workspace-slug
```

### Connect

```javascript
const { connect } = require('@hcengineering/api-client');
require('dotenv').config({ path: process.env.HULY_ENV_PATH });

async function withHuly(fn) {
  const client = await connect(process.env.HULY_URL, {
    email: process.env.HULY_EMAIL,
    password: process.env.HULY_PASSWORD,
    workspace: process.env.HULY_WORKSPACE,
    connectionTimeout: 30000,
  });
  try {
    return await fn(client);
  } finally {
    await client.close();
  }
}

// Usage:
await withHuly(async (client) => {
  const projects = await client.findAll('tracker:class:Project', {});
  console.log(projects.length, 'projects');
});
```

## API methods

| Method                                                                            | Use for                         | Returns              |
| --------------------------------------------------------------------------------- | ------------------------------- | -------------------- |
| `findAll(class, query, options?)`                                                 | List/search                     | Array                |
| `findOne(class, query, options?)`                                                 | Find single                     | Object or undefined  |
| `createDoc(class, space, data, id?)`                                              | Create (direct docs)            | void                 |
| `addCollection(class, space, attachedTo, attachedToClass, collection, data, id?)` | Create (attached docs — Issues) | void                 |
| `updateDoc(class, space, id, operations, returnUpdated?)`                         | Update                          | void or {object}     |
| `removeDoc(class, space, id)`                                                     | Delete                          | void                 |
| `uploadMarkup(class, id, field, content, format)`                                 | Convert markdown to Huly format | string (content ref) |
| `fetchMarkup(class, id, field, content, format)`                                  | Convert Huly format to markdown | string (markdown)    |

## Console output

The connection prints many `no document found, failed to apply model transaction` warnings. These
are **harmless** — they're internal model sync noise. Filter with:

```bash
node script.cjs 2>&1 | grep -v "no document found"
```

## Cloud vs Self-hosted

|               | Cloud                                      | Self-hosted                       |
| ------------- | ------------------------------------------ | --------------------------------- |
| URL           | `https://huly.app`                         | `http://localhost:8087` (default) |
| Auth          | email + password (set in account settings) | email + password                  |
| API stability | ✅ Working (2026-04-21)                    | ⚠ Known auth issues (GitHub #11)  |
| WebSocket     | wss:// (auto)                              | ws:// or wss://                   |
