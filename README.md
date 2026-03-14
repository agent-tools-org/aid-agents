# aid-agents — Community Agent Store

Agent definitions for [aid](https://github.com/sunoj/ai-dispatch) (ai-dispatch).

## Usage

```bash
aid store browse                    # List available agents
aid store show community/aider      # Preview agent config
aid store install community/aider   # Install to ~/.aid/agents/
```

## Contributing

Add your agent definition as a TOML file under `agents/<publisher>/<name>.toml`.
See existing definitions for format reference.

Then add an entry to `index.json` and submit a PR.

## Format

See [Custom Agent Docs](https://aid.agent-tools.org) for the TOML schema.
