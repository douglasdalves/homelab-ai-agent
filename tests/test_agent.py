import json
import unittest
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch

from mcp.types import Tool

from agent.agent import (
    ALLOWED_TOOL_NAMES,
    _confirm_mutation,
    _execute_tool,
    _parse_tool_arguments,
    _select_allowed_tools,
)


def _tool(name):
    return Tool(
        name=name,
        description=name,
        inputSchema={"type": "object", "properties": {}},
    )


class AgentSafetyTests(unittest.IsolatedAsyncioTestCase):
    def test_selects_only_expected_tools(self):
        tools = [_tool(name) for name in sorted(ALLOWED_TOOL_NAMES)]
        tools.append(_tool("deploy_homelab"))

        selected = _select_allowed_tools(tools)

        self.assertEqual({tool.name for tool in selected}, ALLOWED_TOOL_NAMES)
        self.assertNotIn("deploy_homelab", {tool.name for tool in selected})

    def test_parses_object_and_json_arguments(self):
        self.assertEqual(
            _parse_tool_arguments({"all_containers": True}), {"all_containers": True}
        )
        self.assertEqual(
            _parse_tool_arguments('{"all_containers": true}'),
            {"all_containers": True},
        )

    def test_rejects_non_object_arguments(self):
        with self.assertRaises(TypeError):
            _parse_tool_arguments("[]")

    def test_write_action_requires_exact_confirmation(self):
        with patch("builtins.input", return_value="sim"):
            self.assertFalse(
                _confirm_mutation(
                    "manage_docker_container",
                    {"action": "stop", "container_id": "test"},
                )
            )

    async def test_declined_write_never_calls_mcp(self):
        session = SimpleNamespace(call_tool=AsyncMock())
        with patch("builtins.input", return_value="nao"):
            result = await _execute_tool(
                session,
                "manage_docker_container",
                {"action": "remove", "container_id": "test"},
            )

        self.assertIn("Acao cancelada", json.loads(result)["error"])
        session.call_tool.assert_not_awaited()

    async def test_unlisted_tool_never_calls_mcp(self):
        session = SimpleNamespace(call_tool=AsyncMock())

        result = await _execute_tool(session, "deploy_homelab", {})

        self.assertFalse(json.loads(result)["success"])
        session.call_tool.assert_not_awaited()


if __name__ == "__main__":
    unittest.main()
