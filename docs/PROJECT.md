# Agente local do Homelab

Agente de terminal que usa o Ollama local e conecta ao servidor MCP do homelab.
Ele disponibiliza somente `get_health`, `list_docker_containers`,
`inspect_docker_container` e `manage_docker_container`. A chamada de
`manage_docker_container` exige que o usuario digite `SIM` no terminal antes
de executar.

## Requisitos

- Python 3.10 ou superior (`mcp==1.28.1` requer Python >= 3.10)
- Ollama instalado no laptop e o modelo `qwen2.5:3b` baixado
- Servidor MCP ativo no Raspberry Pi
- Tunel SSH do laptop para o Pi ativo enquanto o agente estiver em uso

O tunel encaminha a porta local `5080` para `127.0.0.1:5080` no Pi. Nao abra a
porta MCP no roteador nem altere `MCP_HOST` para `0.0.0.0`.

## Instalacao no Windows

Com o tunel SSH aberto em outra janela do PowerShell:

```powershell
cd C:\caminho\para\homelab-ai-agent
py -3.13 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r .\config\requirements.txt
if (-not (Test-Path .\config\.env)) { Copy-Item .\config\.env.example .\config\.env }
```

Edite `config\.env` apenas se o endereco ou o nome do modelo forem diferentes
dos valores padrao. O arquivo `config\.env` local e ignorado pelo Git.

## Execucao

```powershell
.\.venv\Scripts\python.exe .\agent\agent.py
```

Digite uma solicitacao em portugues. Para encerrar, digite `sair`. Consultas
de estado nao pedem confirmacao; para gerenciar um container, confira a acao e
o identificador exibidos e digite exatamente `SIM` para autorizar.

## Validacao de desenvolvimento

Na branch de feature, execute os testes focados com:

```powershell
.\.venv\Scripts\python.exe -m unittest discover -s tests -v
```
