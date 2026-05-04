# Issues — Huly API Reference

## Create an issue

Issues are `AttachedDoc` — use `addCollection`, NOT `createDoc`.

```javascript
const { generateId, SortingOrder } = require('@hcengineering/core');
const { makeRank } = require('@hcengineering/rank');

async function createIssue(
  client,
  projectId,
  projectIdentifier,
  {
    title,
    description = '',
    priority = 3,
    componentId = null,
    milestoneId = null,
    status = 'tracker:status:Backlog',
  }
) {
  const issueId = generateId();

  // Increment project sequence
  const incResult = await client.updateDoc(
    'tracker:class:Project',
    'core:space:Space',
    projectId,
    { $inc: { sequence: 1 } },
    true
  );
  const seq = incResult.object.sequence;

  // Get rank for ordering
  const lastOne = await client.findOne(
    'tracker:class:Issue',
    { space: projectId },
    { sort: { rank: SortingOrder.Descending } }
  );

  await client.addCollection(
    'tracker:class:Issue',
    projectId,
    projectId,
    'tracker:class:Project',
    'issues',
    {
      title,
      description: description || '',
      status,
      number: seq,
      kind: 'tracker:taskTypes:Issue',
      identifier: `${projectIdentifier}-${seq}`,
      priority, // 0=NoPriority, 1=Urgent, 2=High, 3=Medium, 4=Low
      assignee: null,
      component: componentId,
      milestone: milestoneId,
      estimation: 0,
      remainingTime: 0,
      reportedTime: 0,
      reports: 0,
      subIssues: 0,
      parents: [],
      childInfo: [],
      dueDate: null,
      rank: makeRank(lastOne?.rank, undefined),
    },
    issueId
  );

  return { issueId, identifier: `${projectIdentifier}-${seq}` };
}
```

## Update an issue

```javascript
await client.updateDoc('tracker:class:Issue', issue.space, issue._id, {
  status: 'tracker:status:Done',
  priority: 2,
  // any field can be updated
});
```

## List issues

```javascript
const issues = await client.findAll('tracker:class:Issue', {
  space: projectId,
  // optional filters:
  status: 'tracker:status:Backlog',
  component: componentId,
  milestone: milestoneId,
});
```

## Find issue by identifier

```javascript
const issue = await client.findOne('tracker:class:Issue', {
  identifier: 'ACPL-5',
});
```

## Priority values

| Value | Meaning     |
| ----- | ----------- |
| 0     | No priority |
| 1     | Urgent      |
| 2     | High        |
| 3     | Medium      |
| 4     | Low         |

## Status values

| Status ref                  | Category  | Display     |
| --------------------------- | --------- | ----------- |
| `tracker:status:Backlog`    | UnStarted | Backlog     |
| `tracker:status:Todo`       | ToDo      | Todo        |
| `tracker:status:InProgress` | Active    | In Progress |
| `tracker:status:Done`       | Won       | Done        |
| `tracker:status:Canceled`   | Lost      | Canceled    |
