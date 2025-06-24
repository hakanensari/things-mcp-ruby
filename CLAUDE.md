# CLAUDE.md

This file provides guidance to LLMs when working with code in this repository.

## Common Development Commands

### Build and Development
- `rake build` - Build the gem locally
- `bundle install` - Install dependencies
- `bundle exec rake rubocop` - Run the linter
- `bin/test_connection` - Quick test to see if Things connection works
- `THINGS_AUTH_TOKEN=xxx bin/test_connection` - Test everything including updates

### Running the Server
- `bundle exec ruby bin/things_mcp_server` - Run from source
- `things_mcp_server` - Run if gem is installed

## Architecture Overview

This MCP server provides AI systems with access to the Things 3 task management app on macOS.

### Core Design

1. **Read/Write Separation**
   - Read operations: Direct SQLite database access (read-only mode)
   - Create operations: Things URL scheme (`things:///add?title=...`)
   - Update operations: Things URL scheme with authentication token

2. **Module Structure**
   - `server.rb`: Dynamically generates MCP tool classes from definitions
   - `tools.rb`: Tool schemas and metadata definitions
   - `handlers.rb`: Request routing and response formatting
   - `database.rb`: SQLite database access layer
   - `url_scheme.rb`: Things URL scheme integration
   - `formatters.rb`: Output formatting utilities

3. **Key Patterns**
   - Modules use `extend self` for singleton behavior
   - Server dynamically creates tool classes from definitions in tools.rb
   - Parameters always converted from symbols to strings
   - Custom error types: `DatabaseError`, `UrlSchemeError`

### Authentication

- Read/Create operations: No authentication required
- Update operations: Require `THINGS_AUTH_TOKEN` environment variable (from Things → Settings → General → Enable Things URLs → Manage)
- Database always opened read-only for safety

### Database Access

The server dynamically finds the Things database by searching `~/Library/Group Containers/` for directories containing "culturedcode.ThingsMac". The team ID prefix varies between installations, so hardcoded paths won't work. Also handles root/sudo contexts.

### Requirements

- Ruby 3.2+ (enforced at runtime in server.rb:10)
- macOS system Ruby is typically too old

### Testing

No test suite. Use `bin/test_connection` to verify everything works.

### Commit Style

- Use lowercase for commit messages (e.g., "add foo" not "Add foo")
- Follow 50/72 rule: subject line ≤50 chars, wrap body at 72
- Use imperative mood ("fix bug" not "fixed bug")