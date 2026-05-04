# Documents — Huly API Reference

## Create a document with rich content

Documents use `createDoc` (NOT `addCollection`). Content must be uploaded via `uploadMarkup` for
proper rendering.

```javascript
const { generateId, SortingOrder } = require('@hcengineering/core');
const { makeRank } = require('@hcengineering/rank');

async function createDocument(client, teamspaceId, { title, markdownContent, parentId = null }) {
  const docId = generateId();

  // Upload content as markdown → Huly internal format
  const content = await client.uploadMarkup(
    'document:class:Document',
    docId,
    'content',
    markdownContent,
    'markdown'
  );

  // Get rank for ordering
  const lastOne = await client.findOne(
    'document:class:Document',
    { space: teamspaceId },
    { sort: { rank: SortingOrder.Descending } }
  );

  await client.createDoc(
    'document:class:Document',
    teamspaceId,
    {
      title,
      content,
      parent: parentId || 'document:ids:NoParent',
      rank: makeRank(lastOne?.rank, undefined),
    },
    docId
  );

  return docId;
}
```

## Read document content as markdown

```javascript
const doc = await client.findOne('document:class:Document', { _id: docId });
if (doc?.content) {
  const markdown = await client.fetchMarkup(
    doc._class,
    doc._id,
    'content',
    doc.content,
    'markdown'
  );
  console.log(markdown);
}
```

## List documents in a teamspace

```javascript
const docs = await client.findAll('document:class:Document', {
  space: teamspaceId,
});
```

## Find teamspace by name

```javascript
const wiki = await client.findOne('document:class:Teamspace', {
  name: 'Wiki',
  archived: false,
});
```

## Document hierarchy (parent-child)

Documents can be nested. Set `parent` to another document's ID:

```javascript
const parentDoc = await createDocument(client, wikiId, {
  title: 'Domain Model',
  markdownContent: '# Domain Model Overview\n\n...',
});

const childDoc = await createDocument(client, wikiId, {
  title: 'ET Construction',
  markdownContent: '# ET Construction Analysis\n\n...',
  parentId: parentDoc, // nested under Domain Model
});
```

## Known limitations

- `uploadMarkup` format: `'markdown'` works. Other formats untested.
- File attachments to documents: see `references/attachments.md` (TBD).
- No native drawio rendering — upload as attachment, reference in content.
