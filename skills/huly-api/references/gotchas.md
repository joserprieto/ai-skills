# Gotchas — Huly Platform API

Known issues, workarounds, and silent failures discovered through trial and error. Updated
continuously as new patterns emerge.

## G-001: Milestone status MUST be numeric

**Symptom**: Milestone created via API but invisible in Huly UI.

**Cause**: `status: 'planned'` (string) instead of `status: 0` (number).

**Fix**: Always use `status: 0` for planned milestones.

```javascript
// ❌ WRONG — invisible in UI
await client.createDoc('tracker:class:Milestone', projectId, {
  label: 'Fase 1-II', status: 'planned', ...
})

// ✅ CORRECT
await client.createDoc('tracker:class:Milestone', projectId, {
  label: 'Fase 1-II', status: 0, ...
})
```

**Discovered**: 2026-04-21 during ACOPLA setup.

## G-002: Issue status MUST be a tracker status ref

**Symptom**: Issues created via API but invisible in project Issues view (visible in milestone
view).

**Cause**: `status: ''` (empty string) or `status: project.defaultIssueStatus` when the project has
no default configured.

**Fix**: Always use explicit status string `'tracker:status:Backlog'`.

**Available statuses**:

- `tracker:status:Backlog` (UnStarted)
- `tracker:status:Todo` (ToDo)
- `tracker:status:InProgress` (Active)
- `tracker:status:Done` (Won)
- `tracker:status:Canceled` (Lost)

**WARNING**: Do NOT use statuses from other modules (e.g., `recruit:taskTypeStatus:Backlog`). The
`.find()` might pick the wrong one. Always use the `tracker:status:*` prefix.

**Discovered**: 2026-04-21 during ACOPLA setup.

## G-003: Issues use addCollection, NOT createDoc

**Symptom**: `Error: createDoc cannot be used for objects inherited from AttachedDoc`

**Cause**: `Issue` inherits from `AttachedDoc` in Huly's data model.

**Fix**: Use `addCollection` with parent reference:

```javascript
await client.addCollection(
  'tracker:class:Issue',    // class
  projectId,                // space
  projectId,                // attachedTo (parent)
  'tracker:class:Project',  // attachedToClass
  'issues',                 // collection name
  { title, status, ... },   // data
  issueId                   // ID
)
```

**Discovered**: 2026-04-21 during ACOPLA setup.

## G-004: Project type determines issue visibility

**Symptom**: Issues exist in DB but don't show in project's Issues view.

**Cause**: Project type (e.g., "Proyecto Kanban") has 0 task types configured. Issues created with
`kind: 'tracker:taskTypes:Issue'` don't match.

**Fix**: Set project type to Classic: `tracker:ids:ClassingProjectType`

```javascript
await client.updateDoc('tracker:class:Project', 'core:space:Space', projectId, {
  type: 'tracker:ids:ClassingProjectType',
  defaultIssueStatus: 'tracker:status:Backlog',
});
```

**Discovered**: 2026-04-21 during ACOPLA setup.

## G-005: npm packages have broken transitive deps

**Symptom**: `npm install @hcengineering/tracker` fails with `ETARGET` for
`@hcengineering/time@^0.7.413` or `@hcengineering/activity@^0.7.413`.

**Cause**: Published packages reference internal dependencies not published to npm.

**Workaround**: Do NOT install `tracker`, `document`, `contact` packages. Use string class IDs:

```javascript
// ❌ BROKEN
const tracker = require('@hcengineering/tracker');
tracker.class.Issue;

// ✅ WORKS
('tracker:class:Issue');
```

Only install: `api-client`, `core`, `rank` (all at `0.7.413`).

**Discovered**: 2026-04-21 during ACOPLA setup.

## G-006: API has NO input validation

**Symptom**: API accepts any value for any field without error. Documents/issues created with
invalid data are silently stored but may not render in UI.

**Impact**: You can set `status: 'patata'` and get a success response. The data is corrupt but the
API won't tell you.

**Mitigation**: Always query valid values FIRST before creating/updating:

```javascript
// Query valid statuses before using them
const statuses = await client.findAll('core:class:Status', {});
const trackerStatuses = statuses.filter((s) => s._id.startsWith('tracker:status:'));
```

**Discovered**: 2026-04-21 during ACOPLA setup.

## G-007: Content field vs uploadMarkup

**Symptom**: Document created but content shows as plain text, no formatting.

**Cause**: Setting `content: '# Heading\n...'` directly stores raw string. Huly expects a special
markup format.

**Fix**: Use `uploadMarkup` BEFORE creating the document:

```javascript
const content = await client.uploadMarkup(
  'document:class:Document', docId, 'content',
  '# My Document\n\nFormatted **content** here.', 'markdown'
)
await client.createDoc('document:class:Document', spaceId, {
  title: 'My Doc', content, ...
}, docId)
```

**Discovered**: 2026-04-21 from huly-examples `document-create.ts`.

## G-008: CJS vs ESM import

**Symptom**: `SyntaxError: Named export 'connect' not found`

**Cause**: `@hcengineering/api-client` is CJS. ESM `import { connect }` fails.

**Fix**: Use CJS require or default import:

```javascript
// CJS (recommended for scripts)
const { connect } = require('@hcengineering/api-client');

// ESM
import pkg from '@hcengineering/api-client';
const { connect } = pkg;
```

**Discovered**: 2026-04-21 during initial API test.
