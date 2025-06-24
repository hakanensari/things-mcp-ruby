# frozen_string_literal: true

require "mcp"
require "things_mcp/server"
require "things_mcp/database"
require "things_mcp/handlers"
require "things_mcp/tools"
require "things_mcp/url_scheme"
require "things_mcp/formatters"

# ThingsMcp provides a Model Context Protocol (MCP) server for Things 3
#
# This module enables integration with Things 3 through both database access and URL scheme operations, providing read
# access to todos, projects, areas, and tags, as well as create and update operations.
module ThingsMcp
  # Base error class for ThingsMcp
  class Error < StandardError; end

  # Error raised when database operations fail
  class DatabaseError < Error; end

  # Error raised when URL scheme operations fail
  class UrlSchemeError < Error; end
end
