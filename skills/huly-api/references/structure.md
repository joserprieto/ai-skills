# Project Structure — Huly API Reference

## Milestones

### Create

```javascript
await client.createDoc(
  'tracker:class:Milestone',
  projectId,
  {
    label: 'Phase 1-I',
    description: 'Prototype + viability',
    status: 0, // MUST be numeric! 0 = planned
    targetDate: null, // timestamp in ms or null
  },
  generateId()
);
```

**CRITICAL**: `status` MUST be `0` (number), NOT `'planned'` (string). See gotcha G-001.

### Status values

| Value | Meaning              |
| ----- | -------------------- |
| `0`   | Planned              |
| `1`   | Active (in progress) |
| `2`   | Completed            |

### List

```javascript
const milestones = await client.findAll('tracker:class:Milestone', { space: projectId });
```

### Update

```javascript
await client.updateDoc('tracker:class:Milestone', projectId, msId, {
  status: 1, // activate
  targetDate: Date.parse('2026-06-01'),
});
```

## Components

### Create

```javascript
await client.createDoc(
  'tracker:class:Component',
  projectId,
  {
    label: 'Domain Model',
    description: 'Domain entities, business rules, and value objects',
    lead: null, // person ref or null
  },
  generateId()
);
```

### List

```javascript
const components = await client.findAll('tracker:class:Component', { space: projectId });
```

### Find by name

```javascript
const comp = components.find((c) => c.label === 'Domain Model');
const compId = comp?._id;
```

## Project configuration

### Change project type

```javascript
// Switch to Classic project (has Issue + Requisito task types)
await client.updateDoc('tracker:class:Project', 'core:space:Space', projectId, {
  type: 'tracker:ids:ClassingProjectType',
  defaultIssueStatus: 'tracker:status:Backlog',
});
```

### Find project by identifier

```javascript
const project = await client.findOne('tracker:class:Project', { identifier: 'ACPL' });
```

### Key project fields

| Field                | Type   | Notes                         |
| -------------------- | ------ | ----------------------------- |
| `identifier`         | string | Short code (e.g., 'ACPL')     |
| `name`               | string | Display name                  |
| `type`               | Ref    | Project type ref              |
| `defaultIssueStatus` | Ref    | Default status for new issues |
| `sequence`           | number | Current issue counter         |
| `members`            | Ref[]  | Member list                   |
