# Layout reference

Who computes the geometry, and when. Measured against draw.io Desktop **31.1.8** on 2026-08-18.

## 1. Decide with a grep, not with the diagram's name

The first question is not "what kind of diagram is this" — that was tested and does not predict the
outcome. Containment, anchored ports and positional notation cut **across** the UML types: a
component diagram without a subsystem is a flat graph, and a state machine with composite states is
not.

Run these against the XML. Any hit means **do not delegate the layout**:

```bash
grep -c 'container=1'   diagram.drawio   # parents with children
grep -c 'exitX='        diagram.drawio   # ports anchored to a boundary
grep -c 'umlLifeline'   diagram.drawio   # geometry is notation, not arrangement
```

| Result          | Layout                            |
| --------------- | --------------------------------- |
| any of them > 0 | place by hand — see §4            |
| all zero        | delegate — pick a profile from §2 |

### Why: the measurement behind the rule

One file, four pages, one pipeline. On the **state machine** page (flat graph) ELK produced a clean
top-to-bottom flow with side branches placed correctly and orthogonal edges avoiding shapes.

On the **component** page (a `«subsystem»` container plus six interface ports) the same pipeline
emptied the container, ejected every child outside it, detached all six port labels into floating
text, and inflated the canvas from 1456×900 to 2530×3176 of mostly dead space.

The prediction going in was that ELK would suit component diagrams and ruin sequence diagrams. It
was wrong, which is why the rule now keys on a grep rather than on a judgement about a page name.

## 2. Profiles

Two, both run and looked at. Each ships a probe in `layouts/probes/` so revalidating after the next
draw.io major is "export these two and look", not an audit.

| Profile                   | Use when                            | Probe result |
| ------------------------- | ----------------------------------- | ------------ |
| `layouts/flow-down.json`  | branching graph, several successors | 805×811      |
| `layouts/flow-right.json` | near-linear chain, landscape output | 1503×237     |

Both share the same base and differ only in `elk.direction`: node and rank spacing **20 / 20**,
`nodePlacement.strategy` **SIMPLE**, `resizeNodes` off, `preserveOrigin` on, orthogonal routing,
rounded corners.

### Two settings that were arrived at the hard way

**Spacing stays at 20 / 20.** The values 40 / 56 came from a design note arguing they "stop the
result looking cramped". Applied to a real diagram they stretch the canvas and read worse, and
raising them does not fix anything else either — tested at 40, the arrowhead defect below persisted
unchanged while the canvas grew 200px wider.

**`nodePlacement.strategy` must be `SIMPLE`, not the `NETWORK_SIMPLEX` default.** With the default,
arrowheads enter shapes from the wrong side: in a chain of equal-height nodes the placement offsets
them vertically, so the orthogonal router leaves by the right edge, climbs, and enters the next
shape through its _top_, pointing downwards instead of along the flow. `NETWORK_SIMPLEX` optimises
total edge length, not alignment.

`SIMPLE` fixed it on both probes: the linear chain became a straight line with arrows entering
head-on, and the branching graph gained a clean central axis with its three branches symmetric in
and out of the merge node. Cost: 72px of height on the branching probe.

**Watch out — ELK reorders branches.** In the branching probe the three branches come out ordered C,
B, A, left to right, reversed from their order in the XML. Harmless when branches are peers; if the
order carries meaning (priority, sequence), the profile will shuffle it without warning.

ELK numeric options are **strings**, not numbers — a numeric value is ignored in silence.
`preserveOrigin` defaults to `false`, which packs the result near the origin; in a pipeline you want
it `true`.

## 3. Notes, legends and anything that is not part of the graph

They get treated as loose nodes and scattered — **unless** the layout is restricted to the graph.

In the app: select only the graph nodes and tick **"use selection as roots"** in the layout dialog.
The note then stays where you put it. In JSON the equivalent is `rootCellIds`.

That still leaves the note outside the layout, so its final position is yours to set: either it
joins the layout and drifts, or it stays out and you place it. There is no third option.

## 4. CLI traps

Both fail silently: the export succeeds and produces the wrong thing.

**`--layout` applies to the first page only.** Verified by md5: with `-p 2`, `-p 3`, `-p 4` the
output was byte-identical to the un-laid-out export. Only page 1 changed. Split a multi-page file
into one file per `<diagram>` block before laying out.

**Pages are numbered from 1.** They were 0-based before v27.0.2, so a script written against 24.x
either errors or exports the wrong page.

```bash
drawio -x -f png --scale 2 --layout "$(cat layouts/flow-down.json)" -o out.png page.drawio
```

## 5. Where the layouts live in the app

The interface never says "ELK". Menu labels map to the JSON identifiers like this (Spanish UI in
brackets):

| Menu item [es]                               | JSON identifier                                  |
| -------------------------------------------- | ------------------------------------------------ |
| Vertical flow [Flujo vertical]               | `elkLayered` with `elk.direction: DOWN`          |
| Horizontal flow [Flujo horizontal]           | `elk.direction: RIGHT`                           |
| Trees [Árbol vertical / horizontal / radial] | `verticalTree` · `horizontalTree` · `radialTree` |
| Parallels [Paralelos]                        | `mxParallelEdgeLayout`                           |
| Orthogonal routing [Enrutamiento ortogonal]  | `orthogonalEdge`                                 |
| **Custom [Personalizado]**                   | where the JSON array is pasted                   |

`Arrange → Layout → Custom` is where a profile gets calibrated: paste, apply, look, adjust. What
ends up in the textarea is what belongs in `layouts/*.json`.

## 6. When placing by hand

Everything §1 sends this way.

- Keep the model on `gridSize`: sizes as grid multiples, every coordinate snapped, at least two
  cells of separation.
- Derive height from line count; fit width per **column**, not per box.
- Small **absolute** corner radius, `verticalAlign=middle` by default.
- Zero overlaps, verified mechanically rather than by eye.
- For trees, contiguous subtree bands plus one vertical bus per parent with pinned `exitX`/`entryX`
  gives zero crossings by construction — prefer it to `jumpStyle=arc`.

## 7. Embedding fonts

`fontFamily=X` alone falls back to the default face wherever X is not installed, CLI exports
included. Embed the family as a `data:text/css` `fontSource`.

Embed **only the weights actually declared**, never a whole family: base64 inside a `data:` URI adds
roughly a third on top of the font's own size, and it lands inside every `.drawio` that carries it.
Brand skills ship the `.woff2` files; see the brand skill's `references/drawio-roles.md`.
