# frozen_string_literal: true

module ThingsMcp
  # MCP tool definitions for Things 3 integration
  #
  # This module defines all available MCP tools with their schemas, descriptions, and parameter definitions for
  # interaction with Things 3.
  module Tools
    class << self
      # Returns all available MCP tool definitions
      #
      # @return [Array<Hash>] Array of tool definition hashes
      def all
        [
          # Basic operations
          {
            name: "get-todos",
            description: "Get todos from Things, optionally filtered by project",
            inputSchema: {
              type: "object",
              properties: {
                project_uuid: {
                  type: "string",
                  description: "Optional UUID of a specific project to get todos from",
                },
                include_items: {
                  type: "boolean",
                  description: "Include checklist items",
                  default: true,
                },
              },
              required: [],
            },
          },
          {
            name: "get-projects",
            description: "Get all projects from Things",
            inputSchema: {
              type: "object",
              properties: {
                include_items: {
                  type: "boolean",
                  description: "Include tasks within projects",
                  default: false,
                },
              },
              required: [],
            },
          },
          {
            name: "get-areas",
            description: "Get all areas from Things",
            inputSchema: {
              type: "object",
              properties: {
                include_items: {
                  type: "boolean",
                  description: "Include projects and tasks within areas",
                  default: false,
                },
              },
              required: [],
            },
          },

          # List views
          {
            name: "get-inbox",
            description: "Get todos from Inbox",
            inputSchema: {
              type: "object",
              properties: {},
              required: [],
            },
          },
          {
            name: "get-today",
            description: "Get todos due today",
            inputSchema: {
              type: "object",
              properties: {},
              required: [],
            },
          },
          {
            name: "get-upcoming",
            description: "Get upcoming todos",
            inputSchema: {
              type: "object",
              properties: {},
              required: [],
            },
          },
          {
            name: "get-anytime",
            description: "Get todos from Anytime list",
            inputSchema: {
              type: "object",
              properties: {},
              required: [],
            },
          },
          {
            name: "get-someday",
            description: "Get todos from Someday list",
            inputSchema: {
              type: "object",
              properties: {},
              required: [],
            },
          },
          {
            name: "get-logbook",
            description: "Get completed todos from Logbook, defaults to last 7 days",
            inputSchema: {
              type: "object",
              properties: {
                period: {
                  type: "string",
                  description: "Time period to look back (e.g., '3d', '1w', '2m', '1y'). Defaults to '7d'",
                  pattern: '^\\d+[dwmy]$',
                },
                limit: {
                  type: "integer",
                  description: "Maximum number of entries to return. Defaults to 50",
                  minimum: 1,
                  maximum: 100,
                },
              },
              required: [],
            },
          },
          {
            name: "get-trash",
            description: "Get trashed todos",
            inputSchema: {
              type: "object",
              properties: {},
              required: [],
            },
          },

          # Tag operations
          {
            name: "get-tags",
            description: "Get all tags",
            inputSchema: {
              type: "object",
              properties: {
                include_items: {
                  type: "boolean",
                  description: "Include items tagged with each tag",
                  default: false,
                },
              },
              required: [],
            },
          },
          {
            name: "get-tagged-items",
            description: "Get items with a specific tag",
            inputSchema: {
              type: "object",
              properties: {
                tag: {
                  type: "string",
                  description: "Tag title to filter by",
                },
              },
              required: ["tag"],
            },
          },

          # Search operations
          {
            name: "search-todos",
            description: "Search todos by title or notes",
            inputSchema: {
              type: "object",
              properties: {
                query: {
                  type: "string",
                  description: "Search term to look for in todo titles and notes",
                },
              },
              required: ["query"],
            },
          },
          {
            name: "search-advanced",
            description: "Advanced todo search with multiple filters",
            inputSchema: {
              type: "object",
              properties: {
                status: {
                  type: "string",
                  enum: ["incomplete", "completed", "canceled"],
                  description: "Filter by todo status",
                },
                start_date: {
                  type: "string",
                  description: "Filter by start date (YYYY-MM-DD)",
                },
                deadline: {
                  type: "string",
                  description: "Filter by deadline (YYYY-MM-DD)",
                },
                tag: {
                  type: "string",
                  description: "Filter by tag",
                },
                area: {
                  type: "string",
                  description: "Filter by area UUID",
                },
                type: {
                  type: "string",
                  enum: ["to-do", "project", "heading"],
                  description: "Filter by item type",
                },
              },
              required: [],
            },
          },

          # Recent items
          {
            name: "get-recent",
            description: "Get recently created items",
            inputSchema: {
              type: "object",
              properties: {
                period: {
                  type: "string",
                  description: "Time period (e.g., '3d', '1w', '2m', '1y')",
                  pattern: '^\\d+[dwmy]$',
                },
              },
              required: ["period"],
            },
          },

          # Things URL Scheme tools
          {
            name: "add-todo",
            description: "Create a new todo in Things",
            inputSchema: {
              type: "object",
              properties: {
                title: {
                  type: "string",
                  description: "Title of the todo",
                },
                notes: {
                  type: "string",
                  description: "Notes for the todo",
                },
                when: {
                  type: "string",
                  description: "When to schedule the todo (today, tomorrow, evening, anytime, someday, or YYYY-MM-DD)",
                },
                deadline: {
                  type: "string",
                  description: "Deadline for the todo (YYYY-MM-DD)",
                },
                tags: {
                  type: "array",
                  items: { type: "string" },
                  description: "Tags to apply to the todo",
                },
                checklist_items: {
                  type: "array",
                  items: { type: "string" },
                  description: "Checklist items to add",
                },
                list_id: {
                  type: "string",
                  description: "ID of project/area to add to",
                },
                list_title: {
                  type: "string",
                  description: "Title of project/area to add to",
                },
                heading: {
                  type: "string",
                  description: "Heading to add under",
                },
              },
              required: ["title"],
            },
          },
          {
            name: "add-project",
            description: "Create a new project in Things",
            inputSchema: {
              type: "object",
              properties: {
                title: {
                  type: "string",
                  description: "Title of the project",
                },
                notes: {
                  type: "string",
                  description: "Notes for the project",
                },
                when: {
                  type: "string",
                  description: "When to schedule the project",
                },
                deadline: {
                  type: "string",
                  description: "Deadline for the project",
                },
                tags: {
                  type: "array",
                  items: { type: "string" },
                  description: "Tags to apply to the project",
                },
                area_id: {
                  type: "string",
                  description: "ID of area to add to",
                },
                area_title: {
                  type: "string",
                  description: "Title of area to add to",
                },
                todos: {
                  type: "array",
                  items: { type: "string" },
                  description: "Initial todos to create in the project",
                },
              },
              required: ["title"],
            },
          },
          {
            name: "update-todo",
            description: "Update an existing todo in Things",
            inputSchema: {
              type: "object",
              properties: {
                id: {
                  type: "string",
                  description: "ID of the todo to update",
                },
                title: {
                  type: "string",
                  description: "New title",
                },
                notes: {
                  type: "string",
                  description: "New notes",
                },
                when: {
                  type: "string",
                  description: "New schedule",
                },
                deadline: {
                  type: "string",
                  description: "New deadline",
                },
                tags: {
                  type: "array",
                  items: { type: "string" },
                  description: "New tags",
                },
                completed: {
                  type: "boolean",
                  description: "Mark as completed",
                },
                canceled: {
                  type: "boolean",
                  description: "Mark as canceled",
                },
              },
              required: ["id"],
            },
          },
          {
            name: "update-project",
            description: "Update an existing project in Things",
            inputSchema: {
              type: "object",
              properties: {
                id: {
                  type: "string",
                  description: "ID of the project to update",
                },
                title: {
                  type: "string",
                  description: "New title",
                },
                notes: {
                  type: "string",
                  description: "New notes",
                },
                when: {
                  type: "string",
                  description: "New schedule",
                },
                deadline: {
                  type: "string",
                  description: "New deadline",
                },
                tags: {
                  type: "array",
                  items: { type: "string" },
                  description: "New tags",
                },
                completed: {
                  type: "boolean",
                  description: "Mark as completed",
                },
                canceled: {
                  type: "boolean",
                  description: "Mark as canceled",
                },
              },
              required: ["id"],
            },
          },
          {
            name: "search-items",
            description: "Search for items in Things",
            inputSchema: {
              type: "object",
              properties: {
                query: {
                  type: "string",
                  description: "Search query",
                },
              },
              required: ["query"],
            },
          },
          {
            name: "show-item",
            description: "Show a specific item or list in Things",
            inputSchema: {
              type: "object",
              properties: {
                id: {
                  type: "string",
                  description: "ID of item to show, or one of: inbox, today, upcoming, anytime, someday, logbook",
                },
                query: {
                  type: "string",
                  description: "Optional query to filter by",
                },
                filter_tags: {
                  type: "array",
                  items: { type: "string" },
                  description: "Optional tags to filter by",
                },
              },
              required: ["id"],
            },
          },
        ]
      end
    end
  end
end
