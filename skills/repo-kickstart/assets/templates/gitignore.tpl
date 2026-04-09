# ── Node.js ──────────────────────────────────────────────────────────
node_modules/
# IMPORTANT: package-lock.json is committed — required by `npm ci` in CI pipeline

# ── Build ────────────────────────────────────────────────────────────
dist/
build/

# ── Testing ──────────────────────────────────────────────────────────
.coverage/
.nyc_output/

# ── IDE ──────────────────────────────────────────────────────────────
.vscode/
.idea/

# ── OS ───────────────────────────────────────────────────────────────
.DS_Store
Thumbs.db

# ── Environment ──────────────────────────────────────────────────────
.env
.env.local

# ── Local-only documents (may contain personal data) ─────────────────
docs/plans/
*.local
*.local.*
