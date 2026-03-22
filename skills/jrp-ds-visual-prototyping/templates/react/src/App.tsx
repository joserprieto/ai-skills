/**
 * Prototype entry point.
 *
 * Replace this component with your prototype.
 * All jrp-ds-* classes and --jrp-ds-* tokens are available.
 */
export function App() {
  return (
    <main style={{ padding: 'var(--jrp-ds-spacing-8)' }}>
      <h1
        style={{
          fontFamily: 'var(--jrp-ds-font-family-brand)',
          color: 'var(--jrp-ds-color-brand-primary)',
          marginBottom: 'var(--jrp-ds-spacing-4)',
        }}
      >
        joserprieto DS Prototype
      </h1>

      <p style={{ marginBottom: 'var(--jrp-ds-spacing-6)' }}>
        Tokens, styles, sprite, and fonts are loaded. Start prototyping below.
      </p>

      {/* Example: DS Chip component */}
      <div style={{ display: 'flex', gap: 'var(--jrp-ds-spacing-2)', flexWrap: 'wrap' }}>
        <span className="jrp-ds-chip" data-variant="default">
          <span className="jrp-ds-chip__label">Default</span>
        </span>
        <span className="jrp-ds-chip" data-variant="primary">
          <span className="jrp-ds-chip__label">Primary</span>
        </span>
        <span className="jrp-ds-chip" data-variant="success">
          <span className="jrp-ds-chip__label">Success</span>
        </span>
        <span className="jrp-ds-chip" data-variant="warning">
          <span className="jrp-ds-chip__label">Warning</span>
        </span>
        <span className="jrp-ds-chip" data-variant="error">
          <span className="jrp-ds-chip__label">Error</span>
        </span>
      </div>

      {/* Example: Tabler icon from sprite */}
      <div style={{ marginTop: 'var(--jrp-ds-spacing-6)' }}>
        <svg width="24" height="24" style={{ color: 'var(--jrp-ds-color-brand-primary)' }}>
          <use href="#tabler-heart" />
        </svg>
        <span style={{ marginLeft: 'var(--jrp-ds-spacing-2)', verticalAlign: 'super' }}>
          Icon from sprite
        </span>
      </div>
    </main>
  );
}
