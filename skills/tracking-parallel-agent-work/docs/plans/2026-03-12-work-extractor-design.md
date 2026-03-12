# Work Extractor Tool — Design Document

Tool para extraer bloques de trabajo desde logs JSONL de Claude Code.

## Objetivo

Extraer automáticamente bloques de trabajo (WorkBlocks) desde los archivos JSONL de conversación de
Claude Code, generando un formato intermedio que un agente AI pueda interpretar para crear entradas
de time-tracking.

## JSONL Schema (Claude Code)

### Ubicación de archivos

```
~/.ai/claude-code/accounts/{account}/profiles/{profile}/projects/{project-path-encoded}/*.jsonl
```

- `{project-path-encoded}`: path del proyecto con `/` reemplazado por `-` y prefijado con `-`
  - Ejemplo: `/Users/joserprieto/Projects/Avincis/efx-sdv` →
    `-Users-joserprieto-Projects-Avincis-efx-sdv`
- Cada archivo JSONL es una conversación (session), identificada por UUID en el nombre del archivo

### Tipos de entrada relevantes

| type                    | Campos clave                                                     | Uso                                       |
| ----------------------- | ---------------------------------------------------------------- | ----------------------------------------- |
| `user`                  | `timestamp`, `message.content`, `cwd`, `sessionId`               | Mensajes del usuario (inicio de bloques)  |
| `assistant`             | `timestamp`, `message.model`, `message.content`, `message.usage` | Respuestas del agente (tool calls, texto) |
| `system`                | `timestamp`, `data`                                              | Contexto del sistema                      |
| `progress`              | `timestamp`, `data`                                              | Progreso de herramientas (bulk, ignorar)  |
| `file-history-snapshot` | `snapshot.timestamp`                                             | Snapshots de archivos                     |

### Campos comunes (user/assistant)

```json
{
  "type": "user|assistant",
  "timestamp": "2026-03-10T02:35:54.802Z", // UTC siempre
  "sessionId": "uuid-de-la-sesion",
  "cwd": "/Users/joserprieto/Projects/...", // directorio de trabajo
  "gitBranch": "main",
  "message": {
    "role": "user|assistant",
    "content": "string | array[{type, text?, tool_use_id?, ...}]",
    "model": "claude-opus-4-6" // solo en assistant
  }
}
```

### Content del usuario

- **Texto**: `message.content` es string
- **Tool result**: `message.content` es array con `[{type: "tool_result", content: "..."}]`

### Content del asistente

- **Texto**: `[{type: "text", text: "..."}]`
- **Tool use**: `[{type: "tool_use", name: "Write|Edit|Bash|...", input: {...}}]`

## Modelo de datos

### WorkBlock (output intermedio)

```yaml
- session_id: '317ca27e-d208-4c4b-8350-135963e3821b'
  project_path: '/Users/joserprieto/Projects/Avincis/efx-sdv'
  account: 'gmail'
  profile: 'standard'
  start_utc: '2026-03-10T02:35:54Z'
  end_utc: '2026-03-10T03:21:10Z'
  duration_minutes: 45
  first_user_message: 'buenas noches, Claude; revisa esta conversación...'
  tools_used:
    - Read: 15
    - Write: 8
    - Edit: 3
    - Bash: 5
    - Agent: 2
  model: 'claude-opus-4-6'
  message_count:
    user: 12
    assistant: 11
```

### DaySummary (agrupación por día)

```yaml
date: '2026-03-10'
timezone: 'Europe/Madrid'
blocks:
  - <WorkBlock>
  - <WorkBlock>
total_blocks: 5
total_duration_minutes: 497
projects:
  - path: '/Users/joserprieto/Projects/Avincis/efx-sdv'
    duration_minutes: 120
  - path: '/Users/joserprieto/Projects/joserprieto/technical-insight-lab'
    duration_minutes: 377
```

## Algoritmo de extracción

### Detección de bloques

Un **bloque de trabajo** se define como una secuencia continua de mensajes user/assistant dentro de
una sesión, donde:

1. El bloque inicia con el primer mensaje `user` (tipo texto, no tool_result)
2. El bloque termina con el último mensaje antes de un gap > `GAP_THRESHOLD` (default: 30 min) o fin
   de sesión
3. Los gaps se detectan entre mensajes consecutivos

### Detección de gaps intra-sesión

Si el gap entre dos mensajes consecutivos > `GAP_THRESHOLD`:

- Cerrar bloque actual
- Abrir nuevo bloque con el siguiente mensaje user

Esto maneja sesiones largas con pausas (comida, descanso, etc.).

### Asignación de fecha (timezone-aware)

- Los timestamps del JSONL son UTC
- Se convierten a la timezone configurada (default: `Europe/Madrid`)
- Un bloque pertenece al día de su `start` en timezone local

## CLI

### Comandos

```bash
# Extraer bloques de un rango de fechas
work-extractor extract --date 2026-03-10
work-extractor extract --from 2026-03-10 --to 2026-03-12

# Listar sesiones disponibles
work-extractor sessions --date 2026-03-10

# Extraer de paths específicos (override del default)
work-extractor extract --date 2026-03-10 --search-path ~/.ai/claude-code/accounts/gmail/
```

### Configuración

```toml
# ~/.config/work-extractor/config.toml (o env vars)
[defaults]
search_path = "~/.ai/claude-code/accounts/*/profiles/*/projects/*/"
timezone = "Europe/Madrid"
gap_threshold_minutes = 30
output_format = "yaml"  # yaml | json
```

## Stack técnico

- **Runtime**: Python 3.12+ (gestionado por mise)
- **Package manager**: uv
- **CLI framework**: click
- **Timezone**: zoneinfo (stdlib Python 3.9+)
- **Output**: PyYAML + json (stdlib)
- **Testing**: pytest

## Estructura del proyecto

```
tracking-parallel-agent-work/
  SKILL.md                          # skill existente (ampliar)
  docs/
    plans/
      2026-03-12-work-extractor-design.md  # este documento
  tool/
    .mise.toml                      # python 3.12
    .python-version                 # 3.12
    pyproject.toml                  # uv project config
    Makefile                        # make extract, make test, etc.
    src/
      work_extractor/
        __init__.py
        cli.py                      # click CLI entry point
        extractor.py                # lógica principal de extracción
        models.py                   # WorkBlock, DaySummary dataclasses
        parsers/
          __init__.py
          claude_code.py            # parser específico de Claude Code JSONL
        formatters/
          __init__.py
          yaml_fmt.py               # output YAML
          json_fmt.py               # output JSON
        config.py                   # configuración y defaults
    tests/
      __init__.py
      test_parser.py
      test_extractor.py
      fixtures/
        sample_session.jsonl        # fixture con datos de test
```

## Decisiones de diseño

### ¿Por qué formato intermedio y no time-tracking directo?

- El formato de time-tracking puede cambiar (workspaces)
- La interpretación semántica ("esto es efx-access-governance") requiere un agente AI
- La tool es mecánica; el agente es interpretativo
- El formato intermedio es reutilizable por cualquier agente/herramienta

### ¿Por qué click y no typer?

- click es más maduro y tiene menos dependencias
- typer añade pydantic como dependencia transitiva
- Para un CLI simple, click es suficiente

### ¿Por qué no argparse?

- click maneja subcomandos de forma más limpia
- Mejor DX para testing (CliRunner)

## Limitaciones conocidas

1. **Solo Claude Code**: otros agentes (OpenCode, geminicli) tendrán parsers diferentes
2. **Trabajo offline no capturado**: leer documentos, pensar, reuniones — el usuario debe añadirlo
3. **Interpretación semántica fuera de scope**: la tool no sabe "qué proyecto es", solo extrae
   bloques mecánicamente
4. **Sesiones que cruzan medianoche**: se asignan al día del start del bloque
