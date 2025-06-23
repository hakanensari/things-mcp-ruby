# Things 3 MCP Server (Ruby)

A (clunky) Model Context Protocol (MCP) server for Things 3, implemented in Ruby.

## Features

- Access Things 3 todos, projects, areas, and tags
- Create and update todos and projects
- Search todos with advanced filters
- Access built-in lists (Inbox, Today, Upcoming, etc.)
- Complete Things URL scheme support

## Prerequisites

1. **Things 3** must be installed on your Mac
2. **Ruby 3.2+** installed (required by the MCP gem dependency)
3. **No authentication required** - the server reads from Things' local database

**Note for macOS users**: The system Ruby is possibly too old. Install a modern Ruby.

## Installation

### Option 1: Using the Released Gem (Recommended)

1. Install the gem:

```bash
gem install things-mcp
```

2. The MCP server will be available as `things_mcp_server` in your PATH.

### Option 2: From Source

1. Clone this repository:

```bash
git clone https://github.com/hakanensari/things-mcp-ruby.git
cd things-mcp-ruby
```

2. Install dependencies:

```bash
bundle install
```

## Testing the Installation

### If Using the Gem

1. **Basic test** (database + create operations):

```bash
test_connection
```

2. **Full test** (including update operations):

```bash
THINGS_AUTH_TOKEN=your_token_here test_connection
```

### If Using from Source

1. **Basic test** (database + create operations):

```bash
bin/test_connection
```

2. **Full test** (including update operations):

```bash
THINGS_AUTH_TOKEN=your_token_here bin/test_connection
```

The test script will:

- ✓ Check if Things app is running
- ✓ Test database connectivity
- ✓ Test handler functionality
- ✓ Create a test todo via URL scheme
- ✓ Verify the todo in the database
- ✓ Test update operations by completing the test todo (if auth token provided)

## Running the MCP Server

### If Using the Gem

```bash
things_mcp_server
```

### If Using from Source

```bash
bundle exec ruby bin/things_mcp_server
```

## Configuration

This MCP server implements the [Model Context Protocol](https://modelcontextprotocol.io/) and can be used with any MCP-compatible AI system.

### Claude Desktop

### Basic Configuration (Read + Create Operations)

Add to your Claude Desktop configuration file:

- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`

#### Using the Released Gem (Recommended)

```json
{
  "mcpServers": {
    "things": {
      "command": "things_mcp_server",
      "env": {
        "THINGSDB": "/Users/YOUR_USERNAME/Library/Group Containers/JLMPQHK86H.com.culturedcode.ThingsMac/Things Database.thingsdatabase/main.sqlite"
      }
    }
  }
}
```

#### Using from Source

```json
{
  "mcpServers": {
    "things": {
      "command": "ruby",
      "args": ["bin/things_mcp_server"],
      "cwd": "/path/to/things-mcp-ruby",
      "env": {
        "THINGSDB": "/Users/YOUR_USERNAME/Library/Group Containers/JLMPQHK86H.com.culturedcode.ThingsMac/Things Database.thingsdatabase/main.sqlite"
      }
    }
  }
}
```

### Full Configuration (Including Update Operations)

For `update-todo` and `update-project` operations, you need to provide a Things authorization token:

1. **Get your authorization token from Things:**

   - Open Things 3
   - Go to **Things → Settings → General**
   - Click **Enable Things URLs**
   - Click **Manage**
   - Copy the authorization token

2. **Add the token to your configuration:**

#### Using the Released Gem

```json
{
  "mcpServers": {
    "things": {
      "command": "things_mcp_server",
      "env": {
        "THINGSDB": "/Users/YOUR_USERNAME/Library/Group Containers/JLMPQHK86H.com.culturedcode.ThingsMac/Things Database.thingsdatabase/main.sqlite",
        "THINGS_AUTH_TOKEN": "your_authorization_token_here"
      }
    }
  }
}
```

#### Using from Source

```json
{
  "mcpServers": {
    "things": {
      "command": "ruby",
      "args": ["bin/things_mcp_server"],
      "cwd": "/path/to/things-mcp-ruby",
      "env": {
        "THINGSDB": "/Users/YOUR_USERNAME/Library/Group Containers/JLMPQHK86H.com.culturedcode.ThingsMac/Things Database.thingsdatabase/main.sqlite",
        "THINGS_AUTH_TOKEN": "your_authorization_token_here"
      }
    }
  }
}
```

**Note:** Replace `YOUR_USERNAME` with your actual macOS username. If you have trouble finding the exact database path, you can run `find ~/Library/Group\ Containers -name "main.sqlite" 2>/dev/null | grep Things` to locate it.

⚠️ **Security Note:** Keep your authorization token private. It allows full access to modify your Things data.

### Other MCP Clients

For other MCP-compatible clients, run the server manually and connect via stdio:

```bash
# Start the MCP server
bundle exec ruby bin/things_mcp_server

# The server communicates via JSON-RPC over stdio
# See the MCP specification for integration details:
# https://modelcontextprotocol.io/specification/
```

## Usage

Once configured, you can use your MCP-compatible AI client to:

- "Show me my todos from today"
- "Create a new todo called 'Buy groceries' for tomorrow"
- "Search for todos containing 'meeting'"
- "Show all my projects"

## Available Tools

### Basic Operations

- `get-todos` - Get todos from Things, optionally filtered by project
- `get-projects` - Get all projects from Things
- `get-areas` - Get all areas from Things

### List Views

- `get-inbox` - Get todos from Inbox
- `get-today` - Get todos due today
- `get-upcoming` - Get upcoming todos
- `get-anytime` - Get todos from Anytime list
- `get-someday` - Get todos from Someday list
- `get-logbook` - Get completed todos from Logbook
- `get-trash` - Get trashed todos

### Tag Operations

- `get-tags` - Get all tags
- `get-tagged-items` - Get items with a specific tag

### Search Operations

- `search-todos` - Search todos by title or notes
- `search-advanced` - Advanced todo search with multiple filters

### Recent Items

- `get-recent` - Get recently created items

### Modification Operations

- `add-todo` - Create a new todo in Things
- `add-project` - Create a new project in Things
- `update-todo` - Update an existing todo ⚠️ _Requires auth token_
- `update-project` - Update an existing project ⚠️ _Requires auth token_

> **Note:** When adding tags to existing todos/projects, the tags must already exist in Things. The URL scheme will not create new tags automatically.

- `show-item` - Show a specific item or list in Things
- `search-items` - Search for items and open in Things

## Development

Run connection tests:

```bash
bin/test_connection
```

Run linter:

```bash
bundle exec rake rubocop
```

Run all development tasks:

```bash
bundle exec rake
```

## License

MIT
