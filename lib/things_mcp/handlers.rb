# frozen_string_literal: true

require "json"
require "things_mcp/database"
require "things_mcp/url_scheme"
require "things_mcp/formatters"

module ThingsMcp
  # Tool call handlers for MCP server
  #
  # This module contains handlers for all MCP tool calls, routing requests to appropriate database or URL scheme
  # operations and formatting responses for the MCP client.
  module Handlers
    extend self

    def handle_tool_call(name, arguments)
      case name
      # Basic operations
      when "get-todos"
        handle_get_todos(arguments)
      when "get-projects"
        handle_get_projects(arguments)
      when "get-areas"
        handle_get_areas(arguments)

      # List views
      when "get-inbox"
        handle_list_view(:inbox)
      when "get-today"
        handle_list_view(:today)
      when "get-upcoming"
        handle_list_view(:upcoming)
      when "get-anytime"
        handle_list_view(:anytime)
      when "get-someday"
        handle_list_view(:someday)
      when "get-logbook"
        handle_get_logbook(arguments)
      when "get-trash"
        handle_list_view(:trash)

      # Tag operations
      when "get-tags"
        handle_get_tags(arguments)
      when "get-tagged-items"
        handle_get_tagged_items(arguments)

      # Search operations
      when "search-todos"
        handle_search_todos(arguments)
      when "search-advanced"
        handle_search_advanced(arguments)

      # Recent items
      when "get-recent"
        handle_get_recent(arguments)

      # URL scheme operations
      when "add-todo"
        handle_add_todo(arguments)
      when "add-project"
        handle_add_project(arguments)
      when "update-todo"
        handle_update_todo(arguments)
      when "update-project"
        handle_update_project(arguments)
      when "search-items"
        handle_search_items(arguments)
      when "show-item"
        handle_show_item(arguments)

      else
        raise "Unknown tool: #{name}"
      end
    end

    private

    def handle_get_todos(args)
      todos = Database.get_todos(
        project_uuid: args["project_uuid"],
        include_items: args.fetch("include_items", true),
      )

      return "No todos found" if todos.empty?

      todos.map { |todo| Formatters.format_todo(todo) }.join("\n\n")
    end

    def handle_get_projects(args)
      projects = Database.get_projects(
        include_items: args.fetch("include_items", false),
      )

      return "No projects found" if projects.empty?

      projects.map { |project| Formatters.format_project(project) }.join("\n\n")
    end

    def handle_get_areas(args)
      areas = Database.get_areas(
        include_items: args.fetch("include_items", false),
      )

      return "No areas found" if areas.empty?

      areas.map { |area| Formatters.format_area(area) }.join("\n\n")
    end

    def handle_list_view(list_name)
      todos = case list_name
      when :inbox then Database.get_inbox
      when :today then Database.get_today
      when :upcoming then Database.get_upcoming
      when :anytime then Database.get_anytime
      when :someday then Database.get_someday
      when :trash then Database.get_trash
      end

      return "No todos in #{list_name.to_s.capitalize}" if todos.empty?

      header = "# #{list_name.to_s.capitalize}\n\n"
      header + todos.map { |todo| Formatters.format_todo(todo) }.join("\n\n")
    end

    def handle_get_logbook(args)
      todos = Database.get_logbook(
        period: args.fetch("period", "7d"),
        limit: args.fetch("limit", 50),
      )

      return "No completed todos found" if todos.empty?

      "# Logbook\n\n" + todos.map { |todo| Formatters.format_todo(todo) }.join("\n\n")
    end

    def handle_get_tags(args)
      tags = Database.get_tags(
        include_items: args.fetch("include_items", false),
      )

      return "No tags found" if tags.empty?

      tags.map { |tag| Formatters.format_tag(tag) }.join("\n")
    end

    def handle_get_tagged_items(args)
      tag = args.fetch("tag")
      items = Database.get_tagged_items(tag)

      return "No items found with tag '#{tag}'" if items.empty?

      "# Items tagged with '#{tag}'\n\n" +
        items.map { |item| Formatters.format_todo(item) }.join("\n\n")
    end

    def handle_search_todos(args)
      query = args.fetch("query")
      todos = Database.search_todos(query)

      return "No todos found matching '#{query}'" if todos.empty?

      "# Search results for '#{query}'\n\n" +
        todos.map { |todo| Formatters.format_todo(todo) }.join("\n\n")
    end

    def handle_search_advanced(args)
      todos = Database.search_advanced(args)

      return "No todos found matching criteria" if todos.empty?

      "# Advanced search results\n\n" +
        todos.map { |todo| Formatters.format_todo(todo) }.join("\n\n")
    end

    def handle_get_recent(args)
      period = args.fetch("period")
      todos = Database.get_recent(period)

      return "No recent items found" if todos.empty?

      "# Recent items (last #{period})\n\n" +
        todos.map { |todo| Formatters.format_todo(todo) }.join("\n\n")
    end

    # URL scheme handlers
    def handle_add_todo(args)
      result = UrlScheme.add_todo(args)

      if result[:success]
        "✅ Todo created: #{args["title"]}"
      else
        "❌ Failed to create todo: #{result[:error]}"
      end
    end

    def handle_add_project(args)
      result = UrlScheme.add_project(args)

      if result[:success]
        "✅ Project created: #{args["title"]}"
      else
        "❌ Failed to create project: #{result[:error]}"
      end
    end

    def handle_update_todo(args)
      unless ENV["THINGS_AUTH_TOKEN"]
        return "❌ Update operations require authentication. Please set THINGS_AUTH_TOKEN environment variable. " \
          "See README for setup instructions."
      end

      result = UrlScheme.update_todo(args)

      if result[:success]
        "✅ Todo updated"
      else
        "❌ Failed to update todo: #{result[:error]}"
      end
    end

    def handle_update_project(args)
      unless ENV["THINGS_AUTH_TOKEN"]
        return "❌ Update operations require authentication. Please set THINGS_AUTH_TOKEN environment variable. " \
          "See README for setup instructions."
      end

      result = UrlScheme.update_project(args)

      if result[:success]
        "✅ Project updated"
      else
        "❌ Failed to update project: #{result[:error]}"
      end
    end

    def handle_search_items(args)
      result = UrlScheme.search_items(args["query"])

      if result[:success]
        "✅ Opened search in Things for: #{args["query"]}"
      else
        "❌ Failed to open search: #{result[:error]}"
      end
    end

    def handle_show_item(args)
      result = UrlScheme.show_item(args)

      if result[:success]
        "✅ Opened item in Things"
      else
        "❌ Failed to show item: #{result[:error]}"
      end
    end
  end
end
