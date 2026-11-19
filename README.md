# Local AI Infrastructure Agent

**Python · Ollama · Model Context Protocol · Docker**

A locally hosted terminal agent that translates natural-language requests into
controlled infrastructure operations. It uses Ollama for local language-model
inference and the Model Context Protocol (MCP) to communicate with a separate
homelab MCP server.

## Key features

- Local LLM inference with Ollama.
- MCP integration with infrastructure tools.
- Docker container health checks, inspection, and management.
- Natural-language interaction from the terminal.
- A restricted tool allowlist and explicit confirmation before container
  changes.

## Architecture

```text
┌────────────────────┐       ┌────────────────────┐
│ User               │──────▶│ Python terminal    │
│ Natural-language   │       │ agent              │
│ request            │       └─────────┬──────────┘
└────────────────────┘                 │
                           ┌───────────┴────────────┐
                           │                        │
                     Ollama local             MCP over HTTP
                     LLM inference                  │
                                            SSH local port forward
                                                    │
                                          ┌─────────▼──────────┐
                                          │ Homelab MCP server │
                                          └─────────┬──────────┘
                                                    │
                                                  Docker
```

The agent connects to Ollama locally. Infrastructure requests travel through
an SSH tunnel to the MCP server; the MCP port does not need to be exposed to
the public internet.

## Example interaction

```text
User: Check the status of my containers.
Agent: Queries the homelab health and container-list tools, then summarizes
       the results.

User: Stop the media container.
Agent: Requests explicit confirmation for the proposed container action.
User: SIM
Agent: Reports the result returned by the MCP server.
```

## Getting started

See [docs/PROJECT.md](docs/PROJECT.md) for requirements, Windows setup,
starting the agent and SSH tunnel, and development checks.
