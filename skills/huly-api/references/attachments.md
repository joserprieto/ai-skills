# Attachments — Huly API Reference

## Status: EXPLORATION NEEDED

File attachment via API is not yet fully documented. This reference will be updated as patterns are
discovered.

## Known from huly-examples

The `document-create.ts` example uses `uploadMarkup` for content but does NOT show file attachment.
The `issue-create.ts` example does NOT show attachments either.

## Hypothesis (to validate)

Huly uses a blob storage for attachments. The API likely has:

1. A blob upload endpoint (possibly via the HTTP API, not WebSocket)
2. An attachment class (possibly `attachment:class:Attachment` or `core:class:Blob`)
3. A way to link attachments to issues or documents

## TODO

- [ ] Explore `attachment:class:Attachment` class
- [ ] Test file upload via API
- [ ] Test drawio file attachment to issues
- [ ] Test image attachment to documents
- [ ] Document working pattern here

## Workaround (current)

For now, link to external files (GitHub raw URLs, SharePoint, etc.) in issue/document descriptions
rather than uploading attachments directly.

<!-- Updated: 2026-04-21 -->
