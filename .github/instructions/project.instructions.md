# Instruções do projeto

## Objetivo
Local AI Agent for Infrastructure Management

Um agente de IA local capaz de interpretar solicitações em linguagem natural e interagir com infraestrutura por meio do Model Context Protocol (MCP).

## Definições do readme
Manter em inglês do readme.md, incluindo visão geral do projeto, principais recursos, com desenho da arquitetura e exemplo de interação. 

Assim, posso apresentar como base de portifólios de projetos de IA local para o público em geral, incluindo recrutadores e empresas de tecnologia.

Demais detalhes técnicos, como requisitos, instalação, execução e validação de desenvolvimento, devem ser mantidos em português no docs/PROJECT.md.

## Analise de código
O código do agente é escrito em Python 3.10 ou superior, com dependências listadas em config/requirements.txt. O agente utiliza o Ollama para inferência local de LLM e se comunica com a infraestrutura via MCP.

Temos o uso de variáveis de ambiente para configuração, com um arquivo em /config `.env`

Analise com ruff e pylint, com regras de estilo de código e boas práticas de desenvolvimento.
Com .pre-commit para validação de código antes do commit, incluindo linting, formatação e testes.

## Estilo de código
É importante manter a consistência do estilo de código, incluindo convenções de nomenclatura, formatação e documentação.