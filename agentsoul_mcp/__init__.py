"""Remote MCP adapter for ChatGPT and other MCP clients."""

from .server import create_app, mcp

__all__ = ["create_app", "mcp"]
