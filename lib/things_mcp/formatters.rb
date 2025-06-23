# frozen_string_literal: true

require "uri"

module ThingsMcp
  # Output formatters for Things 3 data
  #
  # This module provides formatting methods to convert raw database records into human-readable text for MCP responses.
  module Formatters
    extend self

    def format_todo(todo)
      lines = []

      # Status indicator
      status_icon = case todo[:status]
      when "completed" then "✅"
      when "canceled" then "❌"
      else "⭕"
      end

      lines << "#{status_icon} **#{todo[:title]}**"
      lines << "   UUID: #{todo[:uuid]}" if todo[:uuid]

      # Notes
      if todo[:notes] && !todo[:notes].empty?
        lines << "   Notes: #{todo[:notes].gsub("\n", " ")}"
      end

      # When/scheduling
      if todo[:when] && todo[:when] != "unknown"
        lines << "   When: #{todo[:when]}"
      end

      if todo[:start_date]
        lines << "   Start: #{todo[:start_date]}"
      end

      if todo[:deadline]
        lines << "   Deadline: #{todo[:deadline]}"
      end

      # Tags
      if todo[:tags] && !todo[:tags].empty?
        lines << "   Tags: #{todo[:tags].join(", ")}"
      end

      # Checklist items
      if todo[:checklist_items] && !todo[:checklist_items].empty?
        lines << "   Checklist:"
        todo[:checklist_items].each do |item|
          check = item[:completed] ? "✓" : "○"
          lines << "     #{check} #{item[:title]}"
        end
      end

      # Metadata
      if todo[:created]
        lines << "   Created: #{todo[:created]}"
      end

      if todo[:modified]
        lines << "   Modified: #{todo[:modified]}"
      end

      lines.join("\n")
    end

    def format_project(project)
      lines = []

      # Status indicator
      status_icon = case project[:status]
      when "completed" then "✅"
      when "canceled" then "❌"
      else "📁"
      end

      lines << "#{status_icon} **#{project[:title]}** (Project)"
      lines << "   UUID: #{project[:uuid]}" if project[:uuid]

      # Notes
      if project[:notes] && !project[:notes].empty?
        lines << "   Notes: #{project[:notes].gsub("\n", " ")}"
      end

      # When/scheduling
      if project[:when] && project[:when] != "unknown"
        lines << "   When: #{project[:when]}"
      end

      if project[:start_date]
        lines << "   Start: #{project[:start_date]}"
      end

      if project[:deadline]
        lines << "   Deadline: #{project[:deadline]}"
      end

      # Tags
      if project[:tags] && !project[:tags].empty?
        lines << "   Tags: #{project[:tags].join(", ")}"
      end

      # Todos within project
      if project[:todos] && !project[:todos].empty?
        lines << "   Todos:"
        project[:todos].each do |todo|
          status = todo[:status] == "completed" ? "✓" : "○"
          lines << "     #{status} #{todo[:title]}"
        end
      end

      lines.join("\n")
    end

    def format_area(area)
      lines = []

      lines << "🏷️ **#{area[:title]}** (Area)"
      lines << "   UUID: #{area[:uuid]}" if area[:uuid]

      # Tags
      if area[:tags] && !area[:tags].empty?
        lines << "   Tags: #{area[:tags].join(", ")}"
      end

      # Projects within area
      if area[:projects] && !area[:projects].empty?
        lines << "   Projects:"
        area[:projects].each do |project|
          lines << "     📁 #{project[:title]}"
        end
      end

      lines.join("\n")
    end

    def format_tag(tag)
      lines = []

      lines << "🏷️ #{tag[:title]}"

      if tag[:items] && !tag[:items].empty?
        lines << "   Items: #{tag[:items].size}"
      end

      lines.join("\n")
    end

  end
end
