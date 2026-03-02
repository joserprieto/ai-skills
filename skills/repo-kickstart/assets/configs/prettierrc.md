#### .prettierrc — Formatting Config

```json
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100,
  "proseWrap": "always"
}
```

**Key choices:**

- **`proseWrap: "always"`** — This is the critical setting for documentation-heavy repos. It
  hard-wraps markdown at `printWidth` (100 characters), which means git diffs show clean, line-level
  changes instead of re-flowing entire paragraphs. Without this, a single word change in a paragraph
  produces a diff of the entire paragraph.
- **`printWidth: 100`** — Wide enough for readable prose, narrow enough for side-by-side diffs.
