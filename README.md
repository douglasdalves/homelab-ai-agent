Local AI Infrastructure Agent
Python · Ollama · MCP · Docker · Infrastructure Automation

Project overview

A locally hosted AI agent that interacts with infrastructure through the Model Context Protocol (MCP).

It uses a local LLM to understand natural language requests, invoke infrastructure tools and return contextual responses.

Key features
- Local LLM inference using Ollama.
- MCP-based infrastructure integration.
- Docker container monitoring and management.
- Natural language interaction.
- Controlled execution of administrative operations.

Architecture


Example interaction

User: Check the status of my Raspberry Pi containers.

Agent: Calls MCP tools and returns infrastructure status.