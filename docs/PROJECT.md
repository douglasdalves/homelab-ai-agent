# Agente local do Homelab

Este repositório contém o agente de terminal que usa o Ollama local e acessa o
servidor MCP do homelab. O agente permite apenas `get_health`,
`list_docker_containers`, `inspect_docker_container` e
`manage_docker_container`. A última ferramenta exige confirmação explícita:
digite `SIM` no terminal antes da execução.

## Requisitos

- Python 3.10 ou superior
- Ollama instalado e o modelo `qwen2.5:3b` baixado
- Servidor MCP ativo no homelab, acessível por SSH
- Cliente OpenSSH instalado e acesso SSH configurado

O túnel encaminha a porta local `5080` para `127.0.0.1:5080` no host remoto.
Não exponha a porta MCP no roteador nem altere `MCP_HOST` para `0.0.0.0`.

## Instalação no Windows

Clone este repositório e execute os comandos na pasta dele. O `.venv` é local
e independente do ambiente de outros repositórios; ele não é versionado. Mesmo
que dois projetos usem a mesma versão do Python, mantenha ambientes separados
para evitar conflitos de dependências.

```powershell
py -3 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r .\config\requirements.txt
if (-not (Test-Path .\config\.env)) { Copy-Item .\config\.env.example .\config\.env }
```

Edite `config\.env` e preencha `SSH_TARGET` com um alias definido em
`%USERPROFILE%\.ssh\config` ou com `usuario@host`. Configure a autenticação SSH
por chave (ou pelo agente SSH); não coloque senhas no arquivo `.env`.
`MCP_URL`, `OLLAMA_BASE_URL` e `OLLAMA_MODEL` podem ser alterados se os valores
locais forem diferentes dos padrões.

O arquivo `config\.env` é local e ignorado pelo Git.

## Iniciar agente e túnel

Dê dois cliques em `start-agent.bat` ou execute `.\start-agent.bat` pelo
PowerShell. O script verifica a API do Ollama e inicia `ollama serve` se ela
ainda não estiver respondendo localmente. Se já estiver em execução, não
inicia outra instância.
Em seguida, abre o túnel SSH e mantém esse túnel ativo durante todo o uso do
agente. Ao encerrar o agente, fecha o túnel SSH e encerra o servidor Ollama
local que atende à API configurada, mesmo que já estivesse ativo antes. Isso
também interrompe outros aplicativos que estejam usando esse Ollama local.

Se `OLLAMA_BASE_URL` apontar para um host remoto, o script não inicia um
servidor Ollama local nem tenta encerrá-lo.

Para criar um atalho, use o caminho completo para `start-agent.bat` como
destino. Assim, não é necessário abrir o projeto no editor para iniciar o
agente. O túnel usa a porta local `5080`; feche outro túnel ou serviço que já
esteja usando essa porta antes de iniciar.

Para iniciar manualmente, abra um terminal com o túnel ativo e execute:

```powershell
.\.venv\Scripts\python.exe .\agent\agent.py
```

Digite uma solicitação em português. Digite `sair` para encerrar. Consultas de
estado não pedem confirmação; para gerenciar um container, confira a ação e o
identificador exibidos e digite exatamente `SIM` para autorizar.

## Validação de desenvolvimento

Execute os testes e as verificações de estilo a partir da raiz do repositório:

```powershell
.\.venv\Scripts\python.exe -m unittest discover -s tests -v
.\.venv\Scripts\python.exe -m pip install pre-commit
.\.venv\Scripts\pre-commit.exe install
.\.venv\Scripts\pre-commit.exe run --all-files
```

O pre-commit está configurado para executar Ruff e formatação. Os testes são
executados separadamente pelo primeiro comando.
