#### .editorconfig — Editor Settings

```ini
# EditorConfig — https://editorconfig.org
root = true

[*]
charset = utf-8
end_of_line = lf
indent_style = space
indent_size = 2
insert_final_newline = true
trim_trailing_whitespace = true

[*.{yml,yaml}]
indent_size = 2

[*.{json,toml}]
indent_size = 2

[*.py]
indent_size = 4

[*.md]
trim_trailing_whitespace = false

[Makefile]
indent_style = tab

[*.hbs]
indent_size = 2

[*.sh]
indent_size = 2
```

**Key overrides:**

- **`[Makefile] indent_style = tab`** — Makefiles REQUIRE tabs for recipe indentation. Spaces cause
  `Makefile:XX: *** missing separator. Stop.` This is the single most common Makefile error.
- **`[*.md] trim_trailing_whitespace = false`** — In markdown, two trailing spaces create a `<br>`
  line break. Trimming them silently removes intentional formatting.
