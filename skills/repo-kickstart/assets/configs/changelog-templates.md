#### .changelog-templates/ — Handlebars Templates

These four files control the format of the auto-generated `CHANGELOG.md`. They are loaded by
`.versionrc.js` via the `writerOpts` property.

##### template.hbs — Main layout

Orchestrates the changelog entry: renders the version header, iterates over commit groups (Features,
Bug Fixes, etc.), and appends the footer (breaking changes).

```handlebars
{{> header}}

{{#each commitGroups}}

{{#if title}}
### {{title}}

{{#each commits}}
{{> commit root=@root}}
{{/each}}

{{/if}}
{{/each}}

{{> footer}}
```

##### header.hbs — Version heading

Renders the `## [X.Y.Z](compare-url) (date)` line for each release.

```handlebars
{{#if isPatch~}}
  ## [{{version}}]({{host}}/{{owner}}/{{repository}}/compare/{{previousTag}}...{{currentTag}}) ({{date}})
{{~else~}}
  ## [{{version}}]({{host}}/{{owner}}/{{repository}}/compare/{{previousTag}}...{{currentTag}}) ({{date}})
{{~/if}}
```

##### commit.hbs — Individual commit line

Formats each commit as a bullet point with optional scope, subject, short hash link, and referenced
issues.

<!-- prettier-ignore -->
```handlebars
*{{#if scope}} **{{scope}}:**
{{~/if}} {{#if subject}}
  {{~subject}}
{{~else}}
  {{~header}}
{{~/if}}

{{~!-- commit link --}} ([{{shortHash}}]({{commitUrlFormat}}))

{{~!-- referenced issues --}}
{{~#if references~}}
  , closes
  {{~#each references}} {{#if this.owner}}
    {{~this.owner}}/
  {{~/if}}
  {{~this.repository}}{{this.prefix}}{{this.issue}}
  {{~/each}}
{{~/if}}
```

##### footer.hbs — Breaking changes

Renders a "BREAKING CHANGES" section at the bottom when any commit includes a `BREAKING CHANGE`
footer.

<!-- prettier-ignore -->
```handlebars
{{#if noteGroups}}
{{#each noteGroups}}

### {{title}}

{{#each notes}}
* {{#if commit.scope}}**{{commit.scope}}:** {{/if}}{{text}}
{{/each}}
{{/each}}

{{/if}}
```
