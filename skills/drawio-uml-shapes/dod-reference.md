# Definition of done, per diagram type

Per-type completion checklists, plus the structural validation that applies to every diagram.
Extracted from `SKILL.md` so the skill body carries decisions and this file carries the checklists
you run against a finished diagram.

## Deployment DoD

- [ ] Every physical/virtual host is a `<<device>>` (cube)
- [ ] Software runtimes are `<<executionEnvironment>>` (component shape)
- [ ] Deployable units are `<<artifact>>` with correct nesting
- [ ] Database engines use `<<database>>` (cylinder)
- [ ] Color roles match element categories
- [ ] Parent-child geometry is relative to parent
- [ ] All edges use orthogonal routing

## Sequence DoD

- [ ] Every participant has a lifeline
- [ ] Messages use correct arrow types (sync=filled, async=open, reply=dashed)
- [ ] Combined fragments have operator labels (alt, loop, opt, etc.)
- [ ] Activation boxes span correct execution periods
- [ ] Lifelines use `container=1`

## State machine DoD

- [ ] Has exactly one initial pseudostate
- [ ] All terminal paths reach a final state or are documented as non-terminating
- [ ] Composite states have clear entry/exit transitions
- [ ] Transitions have `trigger [guard] / effect` labels
- [ ] Choice pseudostates have guards on all outgoing transitions

## Component DoD

- [ ] Components expose provided interfaces (lollipop)
- [ ] Dependencies shown as required interfaces (socket) or dashed arrows
- [ ] Subsystems group related components
- [ ] Ports shown where components cross boundaries

## Package/Class DoD

- [ ] Classes have attributes and methods in separate compartments
- [ ] Relationships use correct UML notation (composition ≠ aggregation)
- [ ] Abstract classes/interfaces have italic names or stereotypes
- [ ] Multiplicity labels present on associations

## Activity DoD

- [ ] Has exactly one initial node
- [ ] All terminal paths reach a final node or are documented as non-terminating
- [ ] Decision nodes have guards on all outgoing edges
- [ ] Fork/Join bars balance (every fork has a matching join)
- [ ] Swimlanes partition responsibilities clearly

## Validation checklist

Before considering a diagram complete, verify the following.

## Structure

- [ ] XML well-formed (`<mxGraphModel>` → `<root>` → cells)
- [ ] Cell 0 (root) and Cell 1 (default parent) present
- [ ] No orphaned cells (every cell has valid parent)
- [ ] Cell IDs are semantic and hyphenated (`dev-appserver`, not `cell-47`)

## Containment

- [ ] Parent-child relationships match UML containment rules
- [ ] Child geometry is relative to parent (NOT absolute)
- [ ] **ALL containers/groupings MUST have `container=1`** in the style string
- [ ] **ALL containers MUST have `collapsible=0`** — never allow collapsing in UML diagrams
- [ ] **ALL containers MUST have `recursiveResize=0`** — children must NOT auto-resize with parent
- [ ] Combined: every container style includes `container=1;collapsible=0;recursiveResize=0;`

## Colors

- [ ] All fills/strokes use semantic role colors (no ad-hoc hex values)
- [ ] EOL/critical elements use `semantic-critical` role
- [ ] Category colors match element purpose

## Typography

- [ ] Font family is `Sans-serif` (or brand override)
- [ ] Font sizes follow scale: titles 14-16px, elements 9-11px, details 7-8px
- [ ] Bold (`fontStyle=1`) for container labels, regular for content

## Edges

- [ ] All edges have `edgeStyle=orthogonalEdgeStyle` (unless justified)
- [ ] Arrow types match UML semantics (see Common Elements)
- [ ] Labels positioned consistently
- [ ] **No unresolved edge crossings** — use `jumpStyle=arc;jumpSize=8;` where edges must cross
- [ ] **Minimize edge crossings** through spatial arrangement before resorting to jumps
- [ ] **CRITICAL: every `edge="1"` cell MUST have a `<mxGeometry relative="1" as="geometry" />`
      child** — even if empty. Self-closing edges (`<mxCell .../>`) cause draw.io to open the file
      with the viewport stuck in an empty corner ("infinite scroll" bug). See Common Mistakes.

## Page

- [ ] Page dimensions set (`pageWidth=1920;pageHeight=1080` for screen, `1169x827` for A3)
- [ ] All shapes within page bounds
