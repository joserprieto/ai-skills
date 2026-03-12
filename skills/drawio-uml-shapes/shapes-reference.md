# Draw.io UML Shapes Reference

Companion reference for `SKILL.md`. Contains exact draw.io style strings for every UML 2.5 shape
type, organized by diagram kind. All styles use **brand-agnostic defaults** based on the Tailwind
Slate palette. A brand layer (loaded separately) overrides fonts and colors at render time; this
file provides the neutral baseline.

## Semantic color defaults

| Role                 | Fill      | Stroke    | Purpose                  |
| -------------------- | --------- | --------- | ------------------------ |
| `surface-device`     | `#F1F5F9` | `#475569` | Device backgrounds       |
| `surface-default`    | `#FFFFFF` | `#475569` | Artifacts, default fills |
| `surface-muted`      | `#F8FAFC` | `#CBD5E1` | Subtle backgrounds       |
| `text-primary`       | —         | `#1E293B` | Main text, fontColor     |
| `text-secondary`     | —         | `#475569` | Secondary text           |
| `category-appserver` | `#FFFBEB` | `#D97706` | App servers, JVMs        |
| `category-database`  | `#EBF5FB` | `#2563EB` | Database engines         |
| `category-broker`    | `#F5F3FF` | `#7C3AED` | Message brokers          |
| `category-proxy`     | `#F0FDF4` | `#16A34A` | Reverse proxies, LBs     |
| `category-container` | `#FFF7ED` | `#EA580C` | Container runtimes       |
| `category-infra`     | `#F1F5F9` | `#64748B` | Infra daemons            |
| `semantic-critical`  | `#FEF2F2` | `#DC2626` | EOL, alerts, failures    |
| `semantic-warning`   | `#FFFBEB` | `#D97706` | Warnings                 |
| `semantic-success`   | `#F0FDF4` | `#16A34A` | OK, healthy              |
| `semantic-info`      | `#EFF6FF` | `#2563EB` | Informational            |
| `special-deployspec` | `#FEF3C7` | `#D97706` | Deployment specs         |
| `special-schema`     | `#EBF5FB` | `#2563EB` | Database schemas         |

**Font:** `Sans-serif` everywhere (brand layer overrides this).

**Default fontColor:** `#1E293B` (`text-primary`).

**Default strokeColor:** `#475569` (`surface-default` stroke).

---

## §1 Deployment Diagram

UML 2.5 §11. Models physical and virtual topology — machines, runtimes, artifacts, and their
relationships.

### Device `<<device>>` [UML 2.0+]

3D cube representing a physical or virtual machine (server, VM, appliance).

Uses `surface-device` colors.

```
shape=cube;size=10;direction=south;boundedLbl=1;verticalAlign=top;align=left;spacingLeft=5;whiteSpace=wrap;html=1;recursiveResize=0;fillColor=#F1F5F9;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=10;fontColor=#1E293B;fontStyle=1;
```

**Key parameters:**

| Parameter           | Value   | Purpose                                           |
| ------------------- | ------- | ------------------------------------------------- |
| `shape=cube`        | native  | 3D cube with perspective (NOT `mxgraph.uml.node`) |
| `size=10`           | pixels  | Depth of the 3D face                              |
| `direction=south`   | —       | Top face visible (standard UML deployment view)   |
| `boundedLbl=1`      | boolean | Label stays within cube body                      |
| `recursiveResize=0` | boolean | Children do not auto-resize with parent           |

**Containment:** Can contain Execution Environment, Artifact, nested Device.

**Common mistake:** `shape=mxgraph.uml.node` renders a flat rectangle with a small 3D tab — always
use `shape=cube`.

### Execution Environment `<<executionEnvironment>>` [UML 2.0+]

Software runtime hosting deployable artifacts (JVM, Docker engine, application server).

Default uses `category-appserver` colors.

```
shape=mxgraph.uml.component;whiteSpace=wrap;html=1;verticalAlign=top;align=left;spacingLeft=5;fillColor=#FFFBEB;strokeColor=#D97706;strokeWidth=1;fontFamily=Sans-serif;fontSize=9;fontColor=#1E293B;
```

**Color role by runtime type:**

| Runtime kind       | Fill      | Stroke    | Semantic role        |
| ------------------ | --------- | --------- | -------------------- |
| App server / JVM   | `#FFFBEB` | `#D97706` | `category-appserver` |
| Database engine    | `#EBF5FB` | `#2563EB` | `category-database`  |
| Message broker     | `#F5F3FF` | `#7C3AED` | `category-broker`    |
| Reverse proxy / LB | `#F0FDF4` | `#16A34A` | `category-proxy`     |
| Container runtime  | `#FFF7ED` | `#EA580C` | `category-container` |
| Infra daemon       | `#F1F5F9` | `#64748B` | `category-infra`     |

**Containment:** Must be child of Device. Can contain Artifact, Component.

### Artifact `<<artifact>>` [UML 2.0+]

Deployable unit — WAR, JAR, binary, configuration bundle.

Uses `surface-default` colors.

```
shape=mxgraph.uml.artifact;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#475569;fontFamily=Sans-serif;fontSize=8;fontColor=#1E293B;
```

**Containment:** Child of Execution Environment or Device. Can contain nested artifacts.

### Deployment Specification `<<deploymentSpecification>>` [UML 2.0+]

Configuration governing how an artifact is deployed (web.xml, Dockerfile, application.yml).

Uses `special-deployspec` colors. `fontStyle=2` renders italic to distinguish from regular
artifacts.

```
shape=mxgraph.uml.artifact;whiteSpace=wrap;html=1;fillColor=#FEF3C7;strokeColor=#D97706;fontFamily=Sans-serif;fontSize=8;fontColor=#1E293B;fontStyle=2;
```

**Containment:** Sibling of the artifact it configures, within the same Execution Environment or
Device.

### Database `<<database>>` [custom]

Database engine rendered as a cylinder. Non-standard UML but universally recognized.

Uses `category-database` colors.

```
shape=cylinder3;size=8;direction=south;boundedLbl=1;whiteSpace=wrap;html=1;verticalAlign=top;align=center;spacingTop=2;fillColor=#EBF5FB;strokeColor=#2563EB;strokeWidth=1;fontFamily=Sans-serif;fontSize=9;fontColor=#1E293B;fontStyle=1;
```

**Key parameters:**

| Parameter         | Value   | Purpose                          |
| ----------------- | ------- | -------------------------------- |
| `shape=cylinder3` | native  | Database cylinder with cap       |
| `size=8`          | pixels  | Height of the top ellipse cap    |
| `boundedLbl=1`    | boolean | Label stays within cylinder body |

**Containment:** Child of Device.

### Schema `<<schema>>` [custom]

Database schema within a database engine. Non-standard UML.

Uses `special-schema` colors.

```
shape=mxgraph.uml.artifact;whiteSpace=wrap;html=1;fillColor=#EBF5FB;strokeColor=#2563EB;fontFamily=Sans-serif;fontSize=8;fontColor=#1E293B;
```

**Containment:** Must be child of Database.

### Manifestation Relationship [UML 2.0+]

Dashed dependency showing artifact-to-component mapping. Label: `<<manifest>>`.

Uses `text-secondary` for stroke and font.

```
edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;endArrow=open;endFill=0;dashed=1;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;
```

### Communication Path [UML 2.0+]

Solid association between devices representing a network link.

```
edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;endArrow=none;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;
```

### Dependency [UML 1.x+]

Dashed arrow showing one element depends on another.

```
edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;endArrow=open;endFill=0;dashed=1;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;
```

### XML example — Java enterprise deployment

```xml
<mxGraphModel>
  <root>
    <mxCell id="0"/>
    <mxCell id="1" parent="0"/>

    <!-- Device: app-server-01 -->
    <mxCell id="dev-appserver" value="&lt;b&gt;&amp;laquo;device&amp;raquo;&lt;/b&gt;&lt;br&gt;app-server-01" style="shape=cube;size=10;direction=south;boundedLbl=1;verticalAlign=top;align=left;spacingLeft=5;whiteSpace=wrap;html=1;recursiveResize=0;fillColor=#F1F5F9;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=10;fontColor=#1E293B;fontStyle=1;" vertex="1" parent="1">
      <mxGeometry x="40" y="40" width="340" height="280" as="geometry"/>
    </mxCell>

    <!-- Execution Environment: OpenJDK 21 -->
    <mxCell id="ee-jvm" value="&lt;b&gt;&amp;laquo;executionEnvironment&amp;raquo;&lt;/b&gt;&lt;br&gt;OpenJDK 21" style="shape=mxgraph.uml.component;whiteSpace=wrap;html=1;verticalAlign=top;align=left;spacingLeft=5;fillColor=#FFFBEB;strokeColor=#D97706;strokeWidth=1;fontFamily=Sans-serif;fontSize=9;fontColor=#1E293B;" vertex="1" parent="dev-appserver">
      <mxGeometry x="20" y="50" width="300" height="200" as="geometry"/>
    </mxCell>

    <!-- Artifact: webapp.war -->
    <mxCell id="art-webapp" value="&lt;b&gt;&amp;laquo;artifact&amp;raquo;&lt;/b&gt;&lt;br&gt;webapp.war" style="shape=mxgraph.uml.artifact;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#475569;fontFamily=Sans-serif;fontSize=8;fontColor=#1E293B;" vertex="1" parent="ee-jvm">
      <mxGeometry x="20" y="50" width="120" height="60" as="geometry"/>
    </mxCell>

    <!-- Deployment Specification: application.yml -->
    <mxCell id="ds-appyml" value="&lt;i&gt;&amp;laquo;deploymentSpec&amp;raquo;&lt;/i&gt;&lt;br&gt;application.yml" style="shape=mxgraph.uml.artifact;whiteSpace=wrap;html=1;fillColor=#FEF3C7;strokeColor=#D97706;fontFamily=Sans-serif;fontSize=8;fontColor=#1E293B;fontStyle=2;" vertex="1" parent="ee-jvm">
      <mxGeometry x="160" y="50" width="120" height="60" as="geometry"/>
    </mxCell>

    <!-- Device: db-server-01 -->
    <mxCell id="dev-dbserver" value="&lt;b&gt;&amp;laquo;device&amp;raquo;&lt;/b&gt;&lt;br&gt;db-server-01" style="shape=cube;size=10;direction=south;boundedLbl=1;verticalAlign=top;align=left;spacingLeft=5;whiteSpace=wrap;html=1;recursiveResize=0;fillColor=#F1F5F9;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=10;fontColor=#1E293B;fontStyle=1;" vertex="1" parent="1">
      <mxGeometry x="480" y="40" width="280" height="280" as="geometry"/>
    </mxCell>

    <!-- Database: PostgreSQL 16 -->
    <mxCell id="db-postgres" value="&lt;b&gt;&amp;laquo;database&amp;raquo;&lt;/b&gt;&lt;br&gt;PostgreSQL 16" style="shape=cylinder3;size=8;direction=south;boundedLbl=1;whiteSpace=wrap;html=1;verticalAlign=top;align=center;spacingTop=2;fillColor=#EBF5FB;strokeColor=#2563EB;strokeWidth=1;fontFamily=Sans-serif;fontSize=9;fontColor=#1E293B;fontStyle=1;" vertex="1" parent="dev-dbserver">
      <mxGeometry x="40" y="50" width="200" height="180" as="geometry"/>
    </mxCell>

    <!-- Schema: app_production -->
    <mxCell id="schema-prod" value="&lt;b&gt;&amp;laquo;schema&amp;raquo;&lt;/b&gt;&lt;br&gt;app_production" style="shape=mxgraph.uml.artifact;whiteSpace=wrap;html=1;fillColor=#EBF5FB;strokeColor=#2563EB;fontFamily=Sans-serif;fontSize=8;fontColor=#1E293B;" vertex="1" parent="db-postgres">
      <mxGeometry x="30" y="50" width="140" height="50" as="geometry"/>
    </mxCell>

    <!-- Dependency: webapp.war -> PostgreSQL -->
    <mxCell id="edge-app-db" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;endArrow=open;endFill=0;dashed=1;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;" edge="1" source="art-webapp" target="db-postgres" parent="1">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>
  </root>
</mxGraphModel>
```

---

## §2 Component Diagram

UML 2.5 §11.6. Models the logical structure of a system — components, interfaces, ports, and their
wiring.

### Component [UML 1.x+]

Standard UML component with the two-rectangle icon on the left side.

Uses `surface-default` colors.

```
shape=mxgraph.uml.component;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=9;fontColor=#1E293B;verticalAlign=top;
```

### Subsystem `<<subsystem>>` [UML 2.0+]

Package with subsystem stereotype. Groups related components into a logical boundary.

Uses `surface-muted` fill with `surface-default` stroke.

```
shape=folder;tabWidth=80;tabHeight=14;tabPosition=left;whiteSpace=wrap;html=1;recursiveResize=0;fillColor=#F8FAFC;strokeColor=#475569;fontFamily=Sans-serif;fontSize=11;fontColor=#1E293B;fontStyle=1;
```

Label format: `<<subsystem>>\nSubsystem Name`.

**Containment:** Groups Component elements. Can nest other Subsystems.

### Provided Interface (lollipop) [UML 2.0+]

Interface that the component implements. Rendered as a small filled circle (ball).

**As a shape** (standalone circle, 16x16 px):

```
ellipse;html=1;aspect=fixed;fillColor=#FFFFFF;strokeColor=#475569;fontFamily=Sans-serif;fontSize=7;fontColor=#1E293B;
```

**As edge endpoint:**

```
endArrow=oval;endFill=1;endSize=12;
```

### Required Interface (socket) [UML 2.0+]

Interface that the component depends on. Rendered as a half-circle (socket).

**As edge endpoint:**

```
endArrow=halfCircle;endFill=0;endSize=16;
```

### Assembly Connector [UML 2.0+]

Ball-and-socket notation connecting a provided interface to a required interface. Combine the
lollipop (provided) and socket (required) endpoints on the same edge.

### Port [UML 2.0+]

Named interaction point placed on a component border. Small square.

Uses `surface-default` colors. Dimensions: 14x14 px.

```
shape=mxgraph.uml.port;html=1;spacingBottom=0;fillColor=#FFFFFF;strokeColor=#475569;fontFamily=Sans-serif;fontSize=7;fontColor=#1E293B;
```

**Containment:** Placed on the border of a Component. Connects internal structure to external
interfaces.

### Delegation Connector [UML 2.0+]

Edge from a port to an internal component, forwarding requests inward.

Uses `text-secondary` stroke.

```
edgeStyle=orthogonalEdgeStyle;html=1;endArrow=open;endFill=0;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;
```

### Dependency [UML 1.x+]

Dashed arrow indicating that one component depends on another.

```
edgeStyle=orthogonalEdgeStyle;html=1;endArrow=open;endFill=0;dashed=1;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;
```

### Realization [UML 1.x+]

Dashed arrow with hollow triangle, showing a component realizes (implements) an interface.

```
edgeStyle=orthogonalEdgeStyle;html=1;endArrow=block;endFill=0;dashed=1;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;
```

### Usage `<<use>>` [UML 2.0+]

Dependency with `<<use>>` stereotype. Same style as Dependency; label: `<<use>>`.

### XML example — 3-tier web application

```xml
<mxGraphModel>
  <root>
    <mxCell id="0"/>
    <mxCell id="1" parent="0"/>

    <!-- Subsystem: Presentation -->
    <mxCell id="sub-presentation" value="&lt;b&gt;&amp;laquo;subsystem&amp;raquo;&lt;/b&gt;&lt;br&gt;Presentation" style="shape=folder;tabWidth=80;tabHeight=14;tabPosition=left;whiteSpace=wrap;html=1;recursiveResize=0;fillColor=#F8FAFC;strokeColor=#475569;fontFamily=Sans-serif;fontSize=11;fontColor=#1E293B;fontStyle=1;" vertex="1" parent="1">
      <mxGeometry x="20" y="20" width="220" height="200" as="geometry"/>
    </mxCell>

    <!-- Component: WebUI -->
    <mxCell id="comp-webui" value="WebUI" style="shape=mxgraph.uml.component;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=9;fontColor=#1E293B;verticalAlign=top;" vertex="1" parent="sub-presentation">
      <mxGeometry x="30" y="50" width="160" height="60" as="geometry"/>
    </mxCell>

    <!-- Provided Interface: IUserInterface (lollipop) -->
    <mxCell id="iface-iui" value="IUserInterface" style="ellipse;html=1;aspect=fixed;fillColor=#FFFFFF;strokeColor=#475569;fontFamily=Sans-serif;fontSize=7;fontColor=#1E293B;" vertex="1" parent="1">
      <mxGeometry x="250" y="82" width="16" height="16" as="geometry"/>
    </mxCell>

    <!-- Subsystem: Business -->
    <mxCell id="sub-business" value="&lt;b&gt;&amp;laquo;subsystem&amp;raquo;&lt;/b&gt;&lt;br&gt;Business" style="shape=folder;tabWidth=80;tabHeight=14;tabPosition=left;whiteSpace=wrap;html=1;recursiveResize=0;fillColor=#F8FAFC;strokeColor=#475569;fontFamily=Sans-serif;fontSize=11;fontColor=#1E293B;fontStyle=1;" vertex="1" parent="1">
      <mxGeometry x="300" y="20" width="220" height="200" as="geometry"/>
    </mxCell>

    <!-- Component: OrderService -->
    <mxCell id="comp-orders" value="OrderService" style="shape=mxgraph.uml.component;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=9;fontColor=#1E293B;verticalAlign=top;" vertex="1" parent="sub-business">
      <mxGeometry x="30" y="50" width="160" height="60" as="geometry"/>
    </mxCell>

    <!-- Subsystem: Data -->
    <mxCell id="sub-data" value="&lt;b&gt;&amp;laquo;subsystem&amp;raquo;&lt;/b&gt;&lt;br&gt;Data" style="shape=folder;tabWidth=80;tabHeight=14;tabPosition=left;whiteSpace=wrap;html=1;recursiveResize=0;fillColor=#F8FAFC;strokeColor=#475569;fontFamily=Sans-serif;fontSize=11;fontColor=#1E293B;fontStyle=1;" vertex="1" parent="1">
      <mxGeometry x="580" y="20" width="220" height="200" as="geometry"/>
    </mxCell>

    <!-- Component: OrderRepository -->
    <mxCell id="comp-repo" value="OrderRepository" style="shape=mxgraph.uml.component;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=9;fontColor=#1E293B;verticalAlign=top;" vertex="1" parent="sub-data">
      <mxGeometry x="30" y="50" width="160" height="60" as="geometry"/>
    </mxCell>

    <!-- Dependency: OrderService -> WebUI (requires IUserInterface) -->
    <mxCell id="edge-orders-ui" style="edgeStyle=orthogonalEdgeStyle;html=1;endArrow=open;endFill=0;dashed=1;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;" edge="1" source="comp-orders" target="comp-webui" parent="1">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>

    <!-- Dependency: OrderService -> OrderRepository -->
    <mxCell id="edge-orders-repo" style="edgeStyle=orthogonalEdgeStyle;html=1;endArrow=open;endFill=0;dashed=1;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;" edge="1" source="comp-orders" target="comp-repo" parent="1">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>
  </root>
</mxGraphModel>
```

---

## §3 Sequence Diagram

UML 2.5 §17. Models interaction between participants over time — lifelines, messages, activation,
and combined fragments.

### Lifeline [UML 1.x+]

Vertical dashed line with a header box. Represents a participant in the interaction.

Uses `surface-device` colors for the header box.

```
shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;html=1;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;size=40;fillColor=#F1F5F9;strokeColor=#475569;fontFamily=Sans-serif;fontSize=10;fontColor=#1E293B;fontStyle=1;
```

**Key parameters:**

| Parameter                 | Value   | Purpose                            |
| ------------------------- | ------- | ---------------------------------- |
| `size=40`                 | pixels  | Height of the header box           |
| `container=1`             | boolean | Activation boxes are children      |
| `portConstraint=eastwest` | —       | Messages attach to left/right only |

### Synchronous Message [UML 1.x+]

Solid line with filled arrowhead. Caller blocks until reply.

Uses `text-primary` stroke.

```
html=1;verticalAlign=bottom;endArrow=block;endFill=1;strokeColor=#1E293B;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#1E293B;
```

### Asynchronous Message [UML 1.x+]

Solid line with open arrowhead. Caller does not block.

Uses `text-primary` stroke.

```
html=1;verticalAlign=bottom;endArrow=open;endFill=0;strokeColor=#1E293B;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#1E293B;
```

### Reply Message [UML 1.x+]

Dashed line with open arrowhead. Return value from callee.

Uses `text-secondary` stroke.

```
html=1;verticalAlign=bottom;endArrow=open;endFill=0;dashed=1;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;
```

### Create Message [UML 2.0+]

Dashed line with open arrowhead targeting a new lifeline header. Creates a new participant at that
point in time.

Uses `text-primary` stroke.

```
html=1;verticalAlign=bottom;endArrow=open;endFill=0;dashed=1;strokeColor=#1E293B;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#1E293B;
```

### Destruction Occurrence [UML 2.0+]

X symbol placed at the bottom of a destroyed lifeline. Dimensions: 30x30 px.

Uses `semantic-critical` stroke.

```
shape=umlDestroy;whiteSpace=wrap;html=1;strokeColor=#DC2626;strokeWidth=2;
```

### Activation Box [UML 1.x+]

Thin rectangle (execution specification) showing when a lifeline is active. Width: 10-15 px. Must be
a child of its lifeline.

Uses `surface-device` colors.

```
fillColor=#F1F5F9;strokeColor=#475569;
```

### Combined Fragment [UML 2.0+]

Frame enclosing a portion of the interaction with an operator keyword: `alt`, `opt`, `loop`,
`break`, `par`, `critical`, `neg`, `assert`, `ignore`, `consider`.

Uses no fill, `surface-default` stroke.

```
shape=umlFrame;whiteSpace=wrap;html=1;fillColor=none;strokeColor=#475569;fontFamily=Sans-serif;fontSize=10;fontColor=#1E293B;fontStyle=1;pointerEvents=0;recursiveResize=0;
```

**Operand divider** (dashed horizontal line separating alternatives within the fragment):

```
line;html=1;strokeWidth=1;strokeColor=#475569;dashed=1;
```

### Interaction Use (ref) [UML 2.0+]

Frame referencing another interaction. Label: `ref` in the pentagon tab, interaction name in the
center.

Uses `surface-muted` fill.

```
shape=umlFrame;whiteSpace=wrap;html=1;fillColor=#F8FAFC;strokeColor=#475569;fontFamily=Sans-serif;fontSize=10;fontColor=#1E293B;fontStyle=1;
```

### Gate [UML 2.5]

Small filled circle on the frame border representing a message endpoint crossing the interaction
boundary. Dimensions: 8x8 px.

Uses `text-primary` fill and stroke.

```
ellipse;html=1;aspect=fixed;fillColor=#1E293B;strokeColor=#1E293B;
```

### State Invariant [UML 2.0+]

Constraint on a lifeline showing a required state at that point. Rounded rectangle.

Uses `surface-muted` colors.

```
rounded=1;arcSize=40;whiteSpace=wrap;html=1;fillColor=#F8FAFC;strokeColor=#475569;fontFamily=Sans-serif;fontSize=8;fontColor=#1E293B;
```

### Lost Message [UML 2.0+]

Message that ends at a filled circle (receiver unknown or out of scope).

**Edge:**

```
html=1;verticalAlign=bottom;endArrow=block;endFill=1;strokeColor=#1E293B;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#1E293B;
```

**Target circle** (12x12 px):

```
ellipse;html=1;aspect=fixed;fillColor=#1E293B;strokeColor=#1E293B;
```

### Found Message [UML 2.0+]

Message originating from a filled circle (sender unknown or out of scope).

**Edge:** Same style as Synchronous Message.

**Source circle** (12x12 px):

```
ellipse;html=1;aspect=fixed;fillColor=#1E293B;strokeColor=#1E293B;
```

### XML example — Authentication flow

```xml
<mxGraphModel>
  <root>
    <mxCell id="0"/>
    <mxCell id="1" parent="0"/>

    <!-- Lifeline: Client -->
    <mxCell id="ll-client" value="Client" style="shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;html=1;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;size=40;fillColor=#F1F5F9;strokeColor=#475569;fontFamily=Sans-serif;fontSize=10;fontColor=#1E293B;fontStyle=1;" vertex="1" parent="1">
      <mxGeometry x="80" y="20" width="100" height="400" as="geometry"/>
    </mxCell>

    <!-- Activation: Client -->
    <mxCell id="act-client" value="" style="fillColor=#F1F5F9;strokeColor=#475569;" vertex="1" parent="ll-client">
      <mxGeometry x="45" y="60" width="10" height="300" as="geometry"/>
    </mxCell>

    <!-- Lifeline: AuthService -->
    <mxCell id="ll-auth" value="AuthService" style="shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;html=1;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;size=40;fillColor=#F1F5F9;strokeColor=#475569;fontFamily=Sans-serif;fontSize=10;fontColor=#1E293B;fontStyle=1;" vertex="1" parent="1">
      <mxGeometry x="280" y="20" width="100" height="400" as="geometry"/>
    </mxCell>

    <!-- Activation: AuthService -->
    <mxCell id="act-auth" value="" style="fillColor=#F1F5F9;strokeColor=#475569;" vertex="1" parent="ll-auth">
      <mxGeometry x="45" y="80" width="10" height="200" as="geometry"/>
    </mxCell>

    <!-- Lifeline: Database -->
    <mxCell id="ll-db" value="Database" style="shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;html=1;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;size=40;fillColor=#F1F5F9;strokeColor=#475569;fontFamily=Sans-serif;fontSize=10;fontColor=#1E293B;fontStyle=1;" vertex="1" parent="1">
      <mxGeometry x="480" y="20" width="100" height="400" as="geometry"/>
    </mxCell>

    <!-- Activation: Database -->
    <mxCell id="act-db" value="" style="fillColor=#F1F5F9;strokeColor=#475569;" vertex="1" parent="ll-db">
      <mxGeometry x="45" y="110" width="10" height="80" as="geometry"/>
    </mxCell>

    <!-- Sync message: login(credentials) -->
    <mxCell id="msg-login" value="login(credentials)" style="html=1;verticalAlign=bottom;endArrow=block;endFill=1;strokeColor=#1E293B;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#1E293B;" edge="1" source="act-client" target="act-auth" parent="1">
      <mxGeometry relative="1" as="geometry">
        <mxPoint y="100" as="sourcePoint"/>
      </mxGeometry>
    </mxCell>

    <!-- Sync message: findUser(username) -->
    <mxCell id="msg-finduser" value="findUser(username)" style="html=1;verticalAlign=bottom;endArrow=block;endFill=1;strokeColor=#1E293B;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#1E293B;" edge="1" source="act-auth" target="act-db" parent="1">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>

    <!-- Reply: userRecord -->
    <mxCell id="msg-userrecord" value="userRecord" style="html=1;verticalAlign=bottom;endArrow=open;endFill=0;dashed=1;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;" edge="1" source="act-db" target="act-auth" parent="1">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>

    <!-- Combined Fragment: alt -->
    <mxCell id="frag-alt" value="alt" style="shape=umlFrame;whiteSpace=wrap;html=1;fillColor=none;strokeColor=#475569;fontFamily=Sans-serif;fontSize=10;fontColor=#1E293B;fontStyle=1;pointerEvents=0;recursiveResize=0;" vertex="1" parent="1">
      <mxGeometry x="200" y="240" width="260" height="140" as="geometry"/>
    </mxCell>

    <!-- Operand divider -->
    <mxCell id="frag-divider" value="[invalid credentials]" style="line;html=1;strokeWidth=1;strokeColor=#475569;dashed=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;" vertex="1" parent="frag-alt">
      <mxGeometry y="70" width="260" height="10" as="geometry"/>
    </mxCell>

    <!-- Reply: authToken (valid path) -->
    <mxCell id="msg-token" value="authToken" style="html=1;verticalAlign=bottom;endArrow=open;endFill=0;dashed=1;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;" edge="1" source="act-auth" target="act-client" parent="1">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>

    <!-- Reply: error 401 (invalid path) -->
    <mxCell id="msg-error" value="error 401" style="html=1;verticalAlign=bottom;endArrow=open;endFill=0;dashed=1;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;" edge="1" source="act-auth" target="act-client" parent="1">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>
  </root>
</mxGraphModel>
```

---

## §4 State Machine Diagram

UML 2.5 §14. Models the lifecycle of an entity through states and transitions — guards, effects,
composite states, and pseudostates.

### Simple State [UML 1.x+]

Rounded rectangle representing a single behavioral state.

Uses `surface-device` colors.

```
rounded=1;arcSize=40;whiteSpace=wrap;html=1;fillColor=#F1F5F9;strokeColor=#475569;fontFamily=Sans-serif;fontSize=10;fontColor=#1E293B;
```

**Internal compartments** (text inside the state):

- `entry / action` — executed on entry
- `exit / action` — executed on exit
- `do / activity` — ongoing activity while in state

**Internal transition** (text inside state, below separator): `trigger [guard] / effect`

### Initial Pseudostate [UML 1.x+]

Filled circle marking the default starting point. Dimensions: 20x20 px.

Uses `text-primary` fill and stroke.

```
ellipse;html=1;aspect=fixed;fillColor=#1E293B;strokeColor=#1E293B;
```

### Final State [UML 1.x+]

Bullseye (double circle) marking termination. Dimensions: 24x24 px.

Uses `text-primary` fill and stroke.

```
ellipse;html=1;shape=doubleCircle;fillColor=#1E293B;strokeColor=#1E293B;
```

### Composite State [UML 1.x+]

State containing sub-states. Rendered as a swimlane container with rounded corners.

Uses `surface-muted` fill.

```
swimlane;fontStyle=1;align=center;startSize=30;rounded=1;arcSize=10;html=1;whiteSpace=wrap;recursiveResize=0;fillColor=#F8FAFC;strokeColor=#475569;fontFamily=Sans-serif;fontSize=11;fontColor=#1E293B;
```

**Containment:** Can contain Simple State, Initial/Final pseudostates, Choice, Junction, Fork/Join,
nested Composite States, and transitions.

### Submachine State [UML 2.0+]

References another state machine diagram. Same style as Simple State, with a trident icon in the
label to indicate submachine reference.

```
rounded=1;arcSize=40;whiteSpace=wrap;html=1;fillColor=#F1F5F9;strokeColor=#475569;fontFamily=Sans-serif;fontSize=10;fontColor=#1E293B;
```

Label format: `StateName : ReferencedMachineName` with trident symbol.

### Shallow History (H) [UML 1.x+]

Remembers only the last direct sub-state. Circle labeled `H`. Dimensions: 24x24 px.

Uses `surface-default` fill.

```
ellipse;html=1;aspect=fixed;fillColor=#FFFFFF;strokeColor=#475569;fontFamily=Sans-serif;fontSize=10;fontColor=#1E293B;fontStyle=1;
```

### Deep History (H\*) [UML 1.x+]

Remembers the full sub-state hierarchy. Same shape as Shallow History. Label: `H*`. Dimensions:
24x24 px.

```
ellipse;html=1;aspect=fixed;fillColor=#FFFFFF;strokeColor=#475569;fontFamily=Sans-serif;fontSize=10;fontColor=#1E293B;fontStyle=1;
```

### Choice Pseudostate [UML 1.x+]

Diamond evaluating a guard at runtime. Dimensions: 40x40 px.

Uses `surface-default` fill.

```
rhombus;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#475569;fontFamily=Sans-serif;fontSize=9;fontColor=#1E293B;
```

### Junction Pseudostate [UML 1.x+]

Small filled circle merging or splitting transitions at compile time (static branching). Dimensions:
12x12 px.

Uses `text-primary` fill and stroke.

```
ellipse;html=1;aspect=fixed;fillColor=#1E293B;strokeColor=#1E293B;
```

### Fork Bar [UML 1.x+]

Horizontal bar splitting one incoming transition into concurrent outgoing transitions.

Uses `text-primary` fill and stroke. Geometry: width=120, height=4.

```
fillColor=#1E293B;strokeColor=#1E293B;
```

### Join Bar [UML 1.x+]

Horizontal bar merging concurrent incoming transitions into one outgoing transition. Same style as
Fork Bar.

Uses `text-primary` fill and stroke. Geometry: width=120, height=4.

```
fillColor=#1E293B;strokeColor=#1E293B;
```

**Vertical variant:** Swap dimensions — width=4, height=120.

### Terminate Pseudostate [UML 2.0+]

X symbol that destroys the entire state machine (no final state needed).

Uses `semantic-critical` stroke. Dimensions: 24x24 px.

```
shape=umlDestroy;whiteSpace=wrap;html=1;strokeColor=#DC2626;strokeWidth=2;
```

### Transition [UML 1.x+]

Edge with label format: `trigger [guard] / effect`.

Uses `text-secondary` stroke.

```
edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;endArrow=open;endFill=0;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;
```

### XML example — Incident lifecycle

```xml
<mxGraphModel>
  <root>
    <mxCell id="0"/>
    <mxCell id="1" parent="0"/>

    <!-- Initial Pseudostate -->
    <mxCell id="sm-initial" value="" style="ellipse;html=1;aspect=fixed;fillColor=#1E293B;strokeColor=#1E293B;" vertex="1" parent="1">
      <mxGeometry x="60" y="30" width="20" height="20" as="geometry"/>
    </mxCell>

    <!-- State: Detected -->
    <mxCell id="sm-detected" value="Detected" style="rounded=1;arcSize=40;whiteSpace=wrap;html=1;fillColor=#F1F5F9;strokeColor=#475569;fontFamily=Sans-serif;fontSize=10;fontColor=#1E293B;" vertex="1" parent="1">
      <mxGeometry x="20" y="80" width="120" height="40" as="geometry"/>
    </mxCell>

    <!-- Choice: severity? -->
    <mxCell id="sm-choice" value="severity?" style="rhombus;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#475569;fontFamily=Sans-serif;fontSize=9;fontColor=#1E293B;" vertex="1" parent="1">
      <mxGeometry x="50" y="160" width="40" height="40" as="geometry"/>
    </mxCell>

    <!-- Composite State: Active -->
    <mxCell id="sm-active" value="Active" style="swimlane;fontStyle=1;align=center;startSize=30;rounded=1;arcSize=10;html=1;whiteSpace=wrap;recursiveResize=0;fillColor=#F8FAFC;strokeColor=#475569;fontFamily=Sans-serif;fontSize=11;fontColor=#1E293B;" vertex="1" parent="1">
      <mxGeometry x="180" y="80" width="300" height="180" as="geometry"/>
    </mxCell>

    <!-- Sub-state: Analyzing -->
    <mxCell id="sm-analyzing" value="Analyzing&lt;br&gt;&lt;hr size=&quot;1&quot;&gt;&lt;font style=&quot;font-size:8px&quot;&gt;entry / assign-team&lt;br&gt;do / investigate&lt;/font&gt;" style="rounded=1;arcSize=40;whiteSpace=wrap;html=1;fillColor=#F1F5F9;strokeColor=#475569;fontFamily=Sans-serif;fontSize=10;fontColor=#1E293B;" vertex="1" parent="sm-active">
      <mxGeometry x="20" y="50" width="120" height="60" as="geometry"/>
    </mxCell>

    <!-- Sub-state: Resolving -->
    <mxCell id="sm-resolving" value="Resolving&lt;br&gt;&lt;hr size=&quot;1&quot;&gt;&lt;font style=&quot;font-size:8px&quot;&gt;entry / apply-fix&lt;br&gt;do / monitor&lt;/font&gt;" style="rounded=1;arcSize=40;whiteSpace=wrap;html=1;fillColor=#F1F5F9;strokeColor=#475569;fontFamily=Sans-serif;fontSize=10;fontColor=#1E293B;" vertex="1" parent="sm-active">
      <mxGeometry x="160" y="50" width="120" height="60" as="geometry"/>
    </mxCell>

    <!-- State: Resolved -->
    <mxCell id="sm-resolved" value="Resolved" style="rounded=1;arcSize=40;whiteSpace=wrap;html=1;fillColor=#F1F5F9;strokeColor=#475569;fontFamily=Sans-serif;fontSize=10;fontColor=#1E293B;" vertex="1" parent="1">
      <mxGeometry x="280" y="310" width="120" height="40" as="geometry"/>
    </mxCell>

    <!-- Final State -->
    <mxCell id="sm-final" value="" style="ellipse;html=1;shape=doubleCircle;fillColor=#1E293B;strokeColor=#1E293B;" vertex="1" parent="1">
      <mxGeometry x="328" y="390" width="24" height="24" as="geometry"/>
    </mxCell>

    <!-- Transitions -->
    <mxCell id="tr-init" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;endArrow=open;endFill=0;strokeColor=#475569;strokeWidth=1;" edge="1" source="sm-initial" target="sm-detected" parent="1">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>

    <mxCell id="tr-detect-choice" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;endArrow=open;endFill=0;strokeColor=#475569;strokeWidth=1;" edge="1" source="sm-detected" target="sm-choice" parent="1">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>

    <mxCell id="tr-choice-analyze" value="[high]" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;endArrow=open;endFill=0;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;" edge="1" source="sm-choice" target="sm-analyzing" parent="1">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>

    <mxCell id="tr-analyze-resolve" value="root-cause-found" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;endArrow=open;endFill=0;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;" edge="1" source="sm-analyzing" target="sm-resolving" parent="1">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>

    <mxCell id="tr-resolve-resolved" value="fix-verified" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;endArrow=open;endFill=0;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;" edge="1" source="sm-resolving" target="sm-resolved" parent="1">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>

    <mxCell id="tr-resolved-final" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;endArrow=open;endFill=0;strokeColor=#475569;strokeWidth=1;" edge="1" source="sm-resolved" target="sm-final" parent="1">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>
  </root>
</mxGraphModel>
```

---

## §5 Package / Class Diagram

UML 2.5 §7, §11.4. Models the structural organization of a system — packages, classes, interfaces,
enumerations, and their relationships.

### Package [UML 1.x+]

Folder-shaped container grouping related elements.

Uses `surface-device` colors.

```
shape=folder;tabWidth=80;tabHeight=14;tabPosition=left;whiteSpace=wrap;html=1;fillColor=#F1F5F9;strokeColor=#475569;fontFamily=Sans-serif;fontSize=11;fontColor=#1E293B;fontStyle=1;
```

### Package Import `<<import>>` [UML 2.0+]

Dashed arrow with open arrowhead and `<<import>>` label. Public import of a package namespace.

```
edgeStyle=orthogonalEdgeStyle;html=1;endArrow=open;endFill=0;dashed=1;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;
```

### Package Access `<<access>>` [UML 2.0+]

Same edge style as Package Import. Label: `<<access>>`. Private import (not re-exported).

```
edgeStyle=orthogonalEdgeStyle;html=1;endArrow=open;endFill=0;dashed=1;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;
```

### Model `<<model>>` [UML 2.0+]

Package with `<<model>>` in the label. Represents a complete, self-contained abstraction.

Same style as Package. Label format: `<<model>>\nModel Name`.

### Class [UML 1.x+]

Swimlane with compartments for name, attributes, and operations.

Uses `surface-default` colors.

**Header (class name):**

```
swimlane;fontStyle=1;align=center;startSize=26;html=1;whiteSpace=wrap;fillColor=#FFFFFF;strokeColor=#475569;fontFamily=Sans-serif;fontSize=11;fontColor=#1E293B;
```

**Compartment separator:**

```
line;strokeWidth=1;fillColor=none;align=left;verticalAlign=middle;spacingTop=-1;spacingLeft=3;spacingRight=10;rotatable=0;labelPosition=left;points=[];portConstraint=eastwest;strokeColor=#475569;
```

**Attribute / method row:**

```
text;align=left;verticalAlign=top;spacingLeft=4;spacingRight=4;overflow=hidden;rotatable=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;fontFamily=Sans-serif;fontSize=9;fontColor=#1E293B;
```

### Abstract Class [UML 1.x+]

Same as Class with `fontStyle=3` (bold + italic) on the header. Label format: `ClassName` in bold
italic, or with `{abstract}` tag.

```
swimlane;fontStyle=3;align=center;startSize=26;html=1;whiteSpace=wrap;fillColor=#FFFFFF;strokeColor=#475569;fontFamily=Sans-serif;fontSize=11;fontColor=#1E293B;
```

### Interface `<<interface>>` [UML 1.x+]

Class box with `<<interface>>` above the name. `startSize=40` for extra header space.

```
swimlane;fontStyle=3;align=center;startSize=40;html=1;whiteSpace=wrap;fillColor=#FFFFFF;strokeColor=#475569;fontFamily=Sans-serif;fontSize=11;fontColor=#1E293B;
```

Label format: `<<interface>>\nInterfaceName`.

### Enumeration `<<enumeration>>` [UML 1.x+]

Class box with `<<enumeration>>` above the name. Attributes compartment lists enum literals.

```
swimlane;fontStyle=1;align=center;startSize=40;html=1;whiteSpace=wrap;fillColor=#FFFFFF;strokeColor=#475569;fontFamily=Sans-serif;fontSize=11;fontColor=#1E293B;
```

Label format: `<<enumeration>>\nEnumName`.

### Association [UML 1.x+]

Solid line, no arrowhead. May include role names and multiplicities at endpoints.

```
endArrow=none;html=1;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;
```

**Directed association** (navigable in one direction):

```
endArrow=open;endFill=0;html=1;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;
```

### Aggregation [UML 1.x+]

Association with a hollow diamond at the whole end. "Has-a" relationship (shared ownership).

```
endArrow=diamond;endFill=0;html=1;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;
```

### Composition [UML 1.x+]

Association with a filled diamond at the whole end. "Owns-a" relationship (exclusive ownership,
lifecycle dependency).

```
endArrow=diamond;endFill=1;html=1;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;
```

### Generalization [UML 1.x+]

Solid line with hollow triangle arrowhead pointing to the superclass.

```
endArrow=block;endFill=0;html=1;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;
```

### Realization [UML 1.x+]

Dashed line with hollow triangle arrowhead. Class implements an interface.

```
endArrow=block;endFill=0;dashed=1;html=1;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;
```

### Dependency [UML 1.x+]

Dashed line with open arrowhead. Weaker coupling than association.

```
endArrow=open;endFill=0;dashed=1;html=1;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;
```

### XML example — Simple domain model

```xml
<mxGraphModel>
  <root>
    <mxCell id="0"/>
    <mxCell id="1" parent="0"/>

    <!-- Package: com.example.orders -->
    <mxCell id="pkg-orders" value="com.example.orders" style="shape=folder;tabWidth=80;tabHeight=14;tabPosition=left;whiteSpace=wrap;html=1;fillColor=#F1F5F9;strokeColor=#475569;fontFamily=Sans-serif;fontSize=11;fontColor=#1E293B;fontStyle=1;" vertex="1" parent="1">
      <mxGeometry x="20" y="20" width="620" height="400" as="geometry"/>
    </mxCell>

    <!-- Interface: IOrderRepository -->
    <mxCell id="iface-repo" value="&lt;b&gt;&lt;i&gt;&amp;laquo;interface&amp;raquo;&lt;br&gt;IOrderRepository&lt;/i&gt;&lt;/b&gt;" style="swimlane;fontStyle=3;align=center;startSize=40;html=1;whiteSpace=wrap;fillColor=#FFFFFF;strokeColor=#475569;fontFamily=Sans-serif;fontSize=11;fontColor=#1E293B;" vertex="1" parent="pkg-orders">
      <mxGeometry x="380" y="40" width="200" height="120" as="geometry"/>
    </mxCell>

    <mxCell id="iface-repo-sep" value="" style="line;strokeWidth=1;fillColor=none;align=left;verticalAlign=middle;spacingTop=-1;spacingLeft=3;spacingRight=10;rotatable=0;labelPosition=left;points=[];portConstraint=eastwest;strokeColor=#475569;" vertex="1" parent="iface-repo">
      <mxGeometry y="40" width="200" height="8" as="geometry"/>
    </mxCell>

    <mxCell id="iface-repo-m1" value="+ findById(id: UUID): Order" style="text;align=left;verticalAlign=top;spacingLeft=4;spacingRight=4;overflow=hidden;rotatable=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;fontFamily=Sans-serif;fontSize=9;fontColor=#1E293B;" vertex="1" parent="iface-repo">
      <mxGeometry y="48" width="200" height="26" as="geometry"/>
    </mxCell>

    <mxCell id="iface-repo-m2" value="+ save(order: Order): void" style="text;align=left;verticalAlign=top;spacingLeft=4;spacingRight=4;overflow=hidden;rotatable=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;fontFamily=Sans-serif;fontSize=9;fontColor=#1E293B;" vertex="1" parent="iface-repo">
      <mxGeometry y="74" width="200" height="26" as="geometry"/>
    </mxCell>

    <!-- Class: Order -->
    <mxCell id="cls-order" value="&lt;b&gt;Order&lt;/b&gt;" style="swimlane;fontStyle=1;align=center;startSize=26;html=1;whiteSpace=wrap;fillColor=#FFFFFF;strokeColor=#475569;fontFamily=Sans-serif;fontSize=11;fontColor=#1E293B;" vertex="1" parent="pkg-orders">
      <mxGeometry x="40" y="40" width="200" height="160" as="geometry"/>
    </mxCell>

    <mxCell id="cls-order-sep1" value="" style="line;strokeWidth=1;fillColor=none;align=left;verticalAlign=middle;spacingTop=-1;spacingLeft=3;spacingRight=10;rotatable=0;labelPosition=left;points=[];portConstraint=eastwest;strokeColor=#475569;" vertex="1" parent="cls-order">
      <mxGeometry y="26" width="200" height="8" as="geometry"/>
    </mxCell>

    <mxCell id="cls-order-a1" value="- id: UUID" style="text;align=left;verticalAlign=top;spacingLeft=4;spacingRight=4;overflow=hidden;rotatable=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;fontFamily=Sans-serif;fontSize=9;fontColor=#1E293B;" vertex="1" parent="cls-order">
      <mxGeometry y="34" width="200" height="26" as="geometry"/>
    </mxCell>

    <mxCell id="cls-order-a2" value="- status: OrderStatus" style="text;align=left;verticalAlign=top;spacingLeft=4;spacingRight=4;overflow=hidden;rotatable=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;fontFamily=Sans-serif;fontSize=9;fontColor=#1E293B;" vertex="1" parent="cls-order">
      <mxGeometry y="60" width="200" height="26" as="geometry"/>
    </mxCell>

    <mxCell id="cls-order-sep2" value="" style="line;strokeWidth=1;fillColor=none;align=left;verticalAlign=middle;spacingTop=-1;spacingLeft=3;spacingRight=10;rotatable=0;labelPosition=left;points=[];portConstraint=eastwest;strokeColor=#475569;" vertex="1" parent="cls-order">
      <mxGeometry y="86" width="200" height="8" as="geometry"/>
    </mxCell>

    <mxCell id="cls-order-m1" value="+ submit(): void" style="text;align=left;verticalAlign=top;spacingLeft=4;spacingRight=4;overflow=hidden;rotatable=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;fontFamily=Sans-serif;fontSize=9;fontColor=#1E293B;" vertex="1" parent="cls-order">
      <mxGeometry y="94" width="200" height="26" as="geometry"/>
    </mxCell>

    <mxCell id="cls-order-m2" value="+ cancel(): void" style="text;align=left;verticalAlign=top;spacingLeft=4;spacingRight=4;overflow=hidden;rotatable=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;fontFamily=Sans-serif;fontSize=9;fontColor=#1E293B;" vertex="1" parent="cls-order">
      <mxGeometry y="120" width="200" height="26" as="geometry"/>
    </mxCell>

    <!-- Class: OrderLine -->
    <mxCell id="cls-orderline" value="&lt;b&gt;OrderLine&lt;/b&gt;" style="swimlane;fontStyle=1;align=center;startSize=26;html=1;whiteSpace=wrap;fillColor=#FFFFFF;strokeColor=#475569;fontFamily=Sans-serif;fontSize=11;fontColor=#1E293B;" vertex="1" parent="pkg-orders">
      <mxGeometry x="40" y="260" width="200" height="100" as="geometry"/>
    </mxCell>

    <mxCell id="cls-orderline-sep" value="" style="line;strokeWidth=1;fillColor=none;align=left;verticalAlign=middle;spacingTop=-1;spacingLeft=3;spacingRight=10;rotatable=0;labelPosition=left;points=[];portConstraint=eastwest;strokeColor=#475569;" vertex="1" parent="cls-orderline">
      <mxGeometry y="26" width="200" height="8" as="geometry"/>
    </mxCell>

    <mxCell id="cls-orderline-a1" value="- quantity: int" style="text;align=left;verticalAlign=top;spacingLeft=4;spacingRight=4;overflow=hidden;rotatable=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;fontFamily=Sans-serif;fontSize=9;fontColor=#1E293B;" vertex="1" parent="cls-orderline">
      <mxGeometry y="34" width="200" height="26" as="geometry"/>
    </mxCell>

    <mxCell id="cls-orderline-a2" value="- unitPrice: BigDecimal" style="text;align=left;verticalAlign=top;spacingLeft=4;spacingRight=4;overflow=hidden;rotatable=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;fontFamily=Sans-serif;fontSize=9;fontColor=#1E293B;" vertex="1" parent="cls-orderline">
      <mxGeometry y="60" width="200" height="26" as="geometry"/>
    </mxCell>

    <!-- Class: OrderRepositoryImpl -->
    <mxCell id="cls-repoimpl" value="&lt;b&gt;OrderRepositoryImpl&lt;/b&gt;" style="swimlane;fontStyle=1;align=center;startSize=26;html=1;whiteSpace=wrap;fillColor=#FFFFFF;strokeColor=#475569;fontFamily=Sans-serif;fontSize=11;fontColor=#1E293B;" vertex="1" parent="pkg-orders">
      <mxGeometry x="380" y="220" width="200" height="60" as="geometry"/>
    </mxCell>

    <!-- Composition: Order -> OrderLine -->
    <mxCell id="edge-composition" value="1..*" style="endArrow=diamond;endFill=1;html=1;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;" edge="1" source="cls-orderline" target="cls-order" parent="pkg-orders">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>

    <!-- Realization: OrderRepositoryImpl -> IOrderRepository -->
    <mxCell id="edge-realization" style="endArrow=block;endFill=0;dashed=1;html=1;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;" edge="1" source="cls-repoimpl" target="iface-repo" parent="pkg-orders">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>
  </root>
</mxGraphModel>
```

---

## §6 Activity Diagram

UML 2.5 §15. Models workflows, business processes, and algorithmic flows — actions, decisions,
concurrency, and swimlanes.

### Action [UML 2.0+]

Rounded rectangle representing a single unit of work.

Uses `surface-device` colors.

```
rounded=1;whiteSpace=wrap;html=1;arcSize=20;fillColor=#F1F5F9;strokeColor=#475569;fontFamily=Sans-serif;fontSize=10;fontColor=#1E293B;
```

### Decision / Merge [UML 1.x+]

Diamond shape. Decision has one incoming and multiple outgoing edges with guards. Merge has multiple
incoming and one outgoing edge.

Uses `surface-default` fill.

```
rhombus;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#475569;fontFamily=Sans-serif;fontSize=9;fontColor=#1E293B;
```

### Fork / Join [UML 1.x+]

Thin bar splitting or merging concurrent flows.

Uses `text-primary` fill and stroke. Geometry: width=100, height=4.

```
fillColor=#1E293B;strokeColor=#1E293B;
```

### Initial Node [UML 1.x+]

Filled circle starting the activity. Dimensions: 20x20 px.

Uses `text-primary` fill and stroke.

```
ellipse;html=1;aspect=fixed;fillColor=#1E293B;strokeColor=#1E293B;
```

### Activity Final [UML 1.x+]

Bullseye terminating the entire activity. Dimensions: 24x24 px.

Uses `text-primary` fill and stroke.

```
ellipse;html=1;shape=doubleCircle;fillColor=#1E293B;strokeColor=#1E293B;
```

### Flow Final [UML 1.x+]

Circle with X terminating a single flow path (not the entire activity). Dimensions: 24x24 px. Label:
the X symbol.

Uses `surface-default` fill with `text-primary` stroke.

```
ellipse;html=1;aspect=fixed;fillColor=#FFFFFF;strokeColor=#1E293B;
```

### Object Node [UML 2.0+]

Rectangle representing data flowing between actions.

Uses `surface-default` colors.

```
whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#475569;fontFamily=Sans-serif;fontSize=9;fontColor=#1E293B;
```

### Swimlane [UML 1.x+]

Vertical partition assigning actions to a responsible actor or system.

Uses `surface-device` colors.

```
shape=swimlane;startSize=30;fontFamily=Sans-serif;fontSize=11;fontColor=#1E293B;fontStyle=1;fillColor=#F1F5F9;strokeColor=#475569;html=1;whiteSpace=wrap;
```

### Signal Send [UML 2.0+]

Convex pentagon representing an outgoing signal emission.

Uses `surface-device` colors.

```
shape=mxgraph.uml25.sendSig;html=1;fillColor=#F1F5F9;strokeColor=#475569;fontFamily=Sans-serif;fontSize=9;fontColor=#1E293B;
```

### Signal Receive [UML 2.0+]

Concave pentagon representing an incoming signal reception.

Uses `surface-device` colors.

```
shape=mxgraph.uml25.recSig;html=1;fillColor=#F1F5F9;strokeColor=#475569;fontFamily=Sans-serif;fontSize=9;fontColor=#1E293B;
```

### Expansion Region [UML 2.0+]

Dashed rounded rectangle grouping actions that execute once per collection element.

Uses no fill, `surface-default` stroke.

```
rounded=1;whiteSpace=wrap;html=1;fillColor=none;strokeColor=#475569;dashed=1;dashPattern=4 4;fontFamily=Sans-serif;fontSize=9;fontColor=#475569;
```

### Interruptible Region [UML 2.0+]

Dashed rounded rectangle with a different dash pattern, grouping actions that can be interrupted by
an exception or event.

Uses no fill, `surface-default` stroke.

```
rounded=1;arcSize=10;whiteSpace=wrap;html=1;fillColor=none;strokeColor=#475569;dashed=1;dashPattern=8 4;fontFamily=Sans-serif;fontSize=9;fontColor=#475569;
```

### Control Flow [UML 2.0+]

Edge connecting actions in sequence. Solid line with open arrowhead.

```
edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;endArrow=open;endFill=0;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;
```

### Object Flow [UML 2.0+]

Edge connecting an action to an object node (or vice versa). Same style as control flow but carries
data.

```
edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;endArrow=open;endFill=0;strokeColor=#475569;strokeWidth=1;fontFamily=Sans-serif;fontSize=8;fontColor=#475569;
```

### Exception Handler [UML 2.0+]

Edge from interruptible region to an exception-handling action. Zigzag arrowhead.

```
edgeStyle=orthogonalEdgeStyle;html=1;endArrow=open;endFill=0;strokeColor=#DC2626;strokeWidth=1;dashed=1;fontFamily=Sans-serif;fontSize=8;fontColor=#DC2626;
```

Uses `semantic-critical` stroke to highlight the exception path.
