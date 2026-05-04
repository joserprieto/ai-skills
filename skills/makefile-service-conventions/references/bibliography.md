# Bibliography — Makefile Service Conventions

Authoritative sources for the patterns codified in this skill. Loaded on demand (not in the base
`SKILL.md` to keep base context light).

## Primary reference: Scripts to Rule Them All

- **Author**: Jon Maddox (GitHub Engineering)
- **Published**: June 30, 2015
- **URL**: <https://github.blog/engineering/scripts-to-rule-them-all/>
- **Reference repository**: <https://github.com/github/scripts-to-rule-them-all>

GitHub codified a convention where every project exposes a fixed set of scripts for common developer
operations. The seven canonical scripts:

| Script             | Purpose                                   |
| ------------------ | ----------------------------------------- |
| `script/bootstrap` | Installs/updates all dependencies         |
| `script/setup`     | Sets up a project for first-time use      |
| `script/update`    | Updates a project to current version      |
| `script/server`    | Starts the application                    |
| `script/test`      | Runs tests                                |
| `script/cibuild`   | Invoked by continuous integration servers |
| `script/console`   | Opens a development console               |

### Core principle (verbatim)

> "Normalizing on script names not only minimizes duplicated effort, it means contributors can do
> the things they need to do without having an extensive fundamental knowledge of how the project
> works."

### Composability

The pattern explicitly encourages composition:

- `script/setup` calls `script/bootstrap` internally
- `script/cibuild` invokes `script/test`

Each script is **language-agnostic** — it can be bash, Ruby, Python, or anything executable. The
contract is the filename and its semantics, not the implementation language.

### Relationship to our Makefile pattern

GitHub's post does not explicitly mention Makefiles. Our adaptation treats the Makefile as a **thin
façade** over the `scripts/` directory:

- Makefile provides the stable entry point (`make start`, `make test`)
- Scripts encode the actual commands (`scripts/serve`, `scripts/test`)
- Contributors can call either layer — `./scripts/serve` works standalone; `make start` is the same
  plus lifecycle orchestration (PID tracking, logs, etc.)

## Design pattern: Facade (Gang of Four, 1994)

**Reference**: Gamma, Helm, Johnson, Vlissides. _Design Patterns: Elements of Reusable
Object-Oriented Software_. Addison-Wesley, 1994. Chapter 4: Structural Patterns — Facade.

### Intent (verbatim from GoF)

> "Provide a unified interface to a set of interfaces in a subsystem. Facade defines a higher-level
> interface that makes the subsystem easier to use."

### Applied to dev tooling

| GoF concept | In our context                                                   |
| ----------- | ---------------------------------------------------------------- |
| Subsystem   | Runtime CLIs (uv, pnpm, npm, go), framework tools (uvicorn,      |
|             | vite, next), orchestration helpers (portless, service-manager)   |
| Facade      | Makefile with canonical targets (`start`, `stop`, `status`, ...) |
| Client      | Human contributor, AI agent, CI system                           |
| Benefit     | Client knows one interface (Makefile), not N stack-specific      |
|             | commands. Subsystem can evolve without breaking the client       |
|             | contract.                                                        |

## Modern alternatives to Makefile (same philosophy)

All three are task runners that explicitly favor orchestration over implementation. They share the
"thin façade" philosophy.

### Taskfile (`taskfile.dev`)

- **URL**: <https://taskfile.dev>
- **Format**: YAML-based (`Taskfile.yml`)
- **Features**: parallel execution, file watching, variable templating, cross-platform
- **Trade-off vs Make**: modern UX but adds a runtime dependency; YAML can become verbose for
  conditional logic

### Just (`just.systems`)

- **URL**: <https://just.systems>
- **Format**: Justfile (Makefile-like syntax, no tabs requirement)
- **Implementation**: Rust, single binary
- **Design principle (from their docs)**: "just is a handy way to save and run project-specific
  commands"
- **Trade-off vs Make**: better error messages, no implicit rules, fewer foot-guns; not
  POSIX-standard (another install step)

### cargo-make

- **URL**: <https://github.com/sagiegurari/cargo-make>
- **Format**: TOML
- **Scope**: Rust projects primarily; integrates with cargo workflows
- **Trade-off vs Make**: tightly coupled to cargo; less useful outside Rust

## Formal standards (none apply to service orchestration)

### POSIX Makefile targets

**Reference**:
[IEEE Std 1003.1-2017, "make"](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/make.html)

POSIX defines canonical targets for **source-code build and install**, not for service
orchestration:

- `all` — build everything
- `install` — install binaries and files
- `clean` — remove build artifacts
- `distclean` — remove everything generated
- `check` — run tests
- `uninstall` — remove installed files

These work for C/C++/autotools projects. There is **no POSIX-defined semantics** for `start`,
`stop`, `status`, `restart`, `logs`, `tail`, or any dev-server lifecycle concerns. The conventions
in this skill are de facto industry standards, not de jure.

### GNU Make manual

**URL**: <https://www.gnu.org/software/make/manual/>

Defines the language (rules, variables, patterns, functions) but stays neutral on target semantics.
The manual's "Standard Targets for Users" section lists
`all/install/clean/distclean/install/uninstall/check` from the GNU Coding Standards — still the
autotools lineage, not dev servers.

## Design pattern context

The "Makefile as wrapper" pattern also aligns with:

- **Unix Philosophy** (McIlroy, 1978): "Make each program do one thing well" — scripts do one thing,
  Makefile composes them
- **Separation of Concerns** (Dijkstra, 1974): orchestration vs implementation are distinct concerns
  and should be in distinct layers
- **Twelve-Factor App** (Wiggins, 2011), factor IV "Backing services": treat the runtime as attached
  resources, interchangeable without changing the app contract — same idea applied to dev tooling

## Further reading

- [Makefiles in 2025: The Build Tool That Refuses to Die](https://ashishacharya.com/posts/makefiles-modern-development/)
- [Justfile became my favorite task runner](https://tduyng.medium.com/justfile-became-my-favorite-task-runner-7a89e3f45d9a)
- [Taskfile: The Modern Makefile for DevOps](https://nhdzhra.medium.com/taskfile-the-modern-makefile-for-devops-431c0fbf6b45)
- [Use Makefile as a task runner for arbitrary projects](https://vinta.ws/code/use-makefile-as-the-task-runner-for-arbitrary-projects.html)
- [Use make as task runner — Szymon Krajewski](https://szymonkrajewski.pl/use-make-as-task-runner/)

## How this bibliography informed the skill

| Skill decision                                | Source                            |
| --------------------------------------------- | --------------------------------- |
| Canonical target names (`start`, `test`, ...) | Scripts to Rule Them All          |
| Scripts as the implementation layer           | Scripts to Rule Them All + Facade |
| `/` namespace for variants                    | Ad hoc (our ecosystem convention) |
| `help` as default goal                        | Developer ergonomics + GNU Make   |
| `.env.local` loaded with `-include`           | Twelve-Factor App, factor III     |
| `make status` with runtime inspection         | Standard ops tooling convention   |
| Semantic naming (`logs/follow` not `tail`)    | Our ecosystem refinement          |
