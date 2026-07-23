# Draw.io Layout Reference — geometry, crossing-free trees, embedded fonts

Companion to `SKILL.md`. Everything here is layout and rendering mechanics: how to place shapes on
the grid, how to draw a hierarchy with zero edge crossings, and how to make a `.drawio` render with
the right typeface anywhere. Brand-agnostic — the colours and fonts come from your brand skill.

---

## 1. Tree / hierarchy layout — zero crossings by construction

For any tree or strict hierarchy (containment, nested states, package trees, taxonomies, org charts)
you can guarantee **zero** edge crossings — no jump arcs — with a left-to-right "comb".

### 1.1 Node placement: contiguous subtree bands

Lay the leaves out in depth-first order, one row each. Give every internal node the y-centre of its
descendant band:

```
center(node) = node.isLeaf
  ? cursor + height/2                                    (then advance the cursor)
  : (center(firstChild) + center(lastChild)) / 2
```

Sibling subtrees then occupy **disjoint vertical bands**, which is the precondition that makes the
rest work.

### 1.2 Edge routing: one vertical bus per parent

Route every parent→child edge through a single vertical line — the bus — sitting in the column gap
immediately right of the parent. Pin the endpoints and give explicit waypoints so draw.io's
auto-router never gets a vote:

```
style: edgeStyle=orthogonalEdgeStyle;html=1;exitX=1;exitY=0.5;entryX=0;entryY=0.5;endArrow=none;
geometry:
  <Array as="points">
    <mxPoint x="BUS" y="parentCenterY"/>
    <mxPoint x="BUS" y="childCenterY"/>
  </Array>
```

`BUS = parent.x + parent.width + gap/2` — the **same** value for every child of that parent, and a
distinct bus x per depth.

### 1.3 Why it cannot cross

All of one parent's edges share a single horizontal trunk out of the parent, then branch vertically
at the bus, then run horizontally into each child: a comb. Two combs can only meet if they share a
bus x **and** overlap in y — impossible, because sibling bands are disjoint (1.1) and each depth has
its own bus x (1.2).

This is structural. Prefer it to `jumpStyle=arc` whenever the graph is a tree; jumps are for graphs
that genuinely aren't planar in the chosen layout.

---

## 2. Geometry on the grid

Keep the whole model on `gridSize` (default 10): every `width`/`height` a multiple of the grid, and
snap every `x`/`y` — including edge waypoints and the bus x — with `round(v/grid)*grid`. Off-grid
coordinates are exactly what make boxes look "almost aligned" and edges kink by a pixel.

| Rule                   | Do this                                                                                                                              |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| **Separation**         | ≥ 2 grid cells between any two shapes, horizontally and vertically. Tighter reads as one block.                                      |
| **Height**             | Derive from the text: `h = pad + step × lineCount` (e.g. `20 + 20 × lines`). Never a fixed height that clips two-line labels.        |
| **Width**              | Fit per **column**, not per box: size each column to its own widest label, then give every box in that column that width.            |
| **Corner radius**      | `rounded=1;absoluteArcSize=1;arcSize=6`. A percentage radius scales with the shape, so tall boxes get a curve that crowds the label. |
| **Vertical alignment** | `verticalAlign=middle` for labelled shapes. Dense text panels (legends, notes) read better `verticalAlign=top`.                      |
| **Overlap**            | Zero. Verify mechanically — parse the model and assert no two vertex bounding boxes intersect.                                       |

**Why width is per column, not per box:** sizing each box to its own text makes the column edges
ragged, and a ragged column costs more readability than the whitespace it saves. The column is the
alignment cue the eye follows.

---

## 3. Embedding fonts offline (portable exports)

`fontFamily=X` alone only works if the renderer already has X installed — CLI/PNG/SVG exports on
another machine silently fall back to the default face. To make a `.drawio` self-contained, embed
the family as a data-URI `fontSource`.

**Verified:** draw.io's exporter honours a `data:text/css` fontSource (24.x, `-e` PNG export).

### 3.1 Procedure

1. Build ONE CSS with an `@font-face` per weight **and** per style — italics too, not just upright —
   each `src:` a `data:font/woff2;base64,…` of that face. Keep the `unicode-range` when a face is
   split into `latin` / `latin-ext`, or the two subsets overwrite each other instead of coexisting.
2. Wrap it: `fontSource = urlencode("data:text/css;base64," + base64(css))`. URL-encode the whole
   value, or `;` `,` `=` `/` will break draw.io's style parser.
3. Put `fontFamily=Family;fontSource=<that>` on **one** cell per family. Every other cell needs only
   `fontFamily=Family` — draw.io registers the `@font-face` globally, so all cells pick it up.

### 3.2 Rules

- **Embed the whole family, not one weight.** Relying on synthetic bold/italic gives smeared
  faux-bold and slanted uprights. Get the real faces — Google Fonts serves them with `ital,wght@…`.
- **Cost is real:** the file grows by the embedded bytes (hundreds of KB for two full families).
  Accept it, or move a font-heavy page into its own file.
- **Check every cell got a family.** A single cell left without `fontFamily` renders in the default
  face and is easy to miss in a dense diagram.

### 3.3 Verify by looking

Export the page (`drawio -x -f png -e -p <page> -o out.png file.drawio`) and actually open the
image. Valid XML proves nothing about whether the font loaded.
