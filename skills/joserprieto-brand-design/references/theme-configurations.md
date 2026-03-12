# Theme Configurations — joserprieto Brand

Copy-paste configurations for diagramming tools. All values derive from the joserprieto OKHSL
palette defined in `SKILL.md`.

## Mermaid Theme Variables

Use `%%{init: ...}%%` to apply joserprieto brand in Mermaid diagrams.

```text
%%{init: {
  "theme": "base",
  "themeVariables": {
    "primaryColor": "#ebf0ec",
    "primaryTextColor": "#141a14",
    "primaryBorderColor": "#3d5a3d",
    "lineColor": "#3c4d3d",
    "secondaryColor": "#d7e1d8",
    "secondaryBorderColor": "#3d5a3d",
    "tertiaryColor": "#eaeff5",
    "tertiaryBorderColor": "#3a5a7a",
    "noteBkgColor": "#f0efe6",
    "noteTextColor": "#141a14",
    "noteBorderColor": "#716404",
    "background": "#fafcfa",
    "mainBkg": "#ebf0ec",
    "nodeBorder": "#3d5a3d",
    "clusterBkg": "#f2f5f2",
    "clusterBorder": "#92a494",
    "titleColor": "#141a14",
    "edgeLabelBackground": "#fafcfa",
    "fontFamily": "Inter, system-ui, sans-serif",
    "fontSize": "14px",
    "actorBkg": "#d7e1d8",
    "actorBorder": "#3d5a3d",
    "actorTextColor": "#141a14",
    "actorLineColor": "#3c4d3d",
    "signalColor": "#3c4d3d",
    "signalTextColor": "#141a14",
    "labelBoxBkgColor": "#ebf0ec",
    "labelBoxBorderColor": "#3d5a3d",
    "labelTextColor": "#141a14",
    "loopTextColor": "#141a14",
    "activationBorderColor": "#3d5a3d",
    "activationBkgColor": "#d7e1d8",
    "sequenceNumberColor": "#fafcfa",
    "errorBkgColor": "#f5eceb",
    "errorTextColor": "#8a3a3a",
    "fillType0": "#ebf0ec",
    "fillType1": "#d7e1d8",
    "fillType2": "#eaf0eb",
    "fillType3": "#eaeff5",
    "fillType4": "#f0efe6",
    "fillType5": "#f5eceb",
    "fillType6": "#f2eee6",
    "fillType7": "#dce2dc"
  }
}}%%
```

## D2 Theme Configuration

```d2
vars: {
  d2-config: {
    theme-id: 0
    theme-overrides: {
      N1: "#ebf0ec"
      N2: "#d8e0da"
      N3: "#b4c2b6"
      N4: "#92a494"
      N5: "#566958"
      N6: "#3c4d3d"
      N7: "#141a14"
      B1: "#d7e1d8"
      B2: "#b1c4b3"
      B3: "#8ca78f"
      B4: "#4d6c50"
      B5: "#3d5a3d"
      B6: "#1e3420"
      AA2: "#f0efe6"
      AA4: "#716404"
      AA5: "#544800"
      AB4: "#3a5a7a"
      AB5: "#2d4a68"
    }
  }
}
```

For D2 diagrams, apply these color overrides. Primary elements use B5 (`#3d5a3d`), neutral
containers use N1-N2, and text uses N7 (`#141a14`).
