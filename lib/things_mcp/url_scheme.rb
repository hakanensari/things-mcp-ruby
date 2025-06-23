# frozen_string_literal: true

require "uri"
require "json"
require "open3"

module ThingsMcp
  # Things 3 URL scheme integration
  #
  # This module provides methods for creating and updating todos and projects using Things 3's URL scheme. It handles
  # authentication tokens for update operations and manages the Things 3 application lifecycle.
  module UrlScheme
    extend self

    THINGS_URL_BASE = "things:///"

    def add_todo(params)
      url_params = {
        "title" => params["title"],
      }

      # Optional parameters
      url_params["notes"] = params["notes"] if params["notes"]
      url_params["when"] = params["when"] if params["when"]
      url_params["deadline"] = params["deadline"] if params["deadline"]
      url_params["tags"] = params["tags"].join(",") if params["tags"]
      url_params["checklist-items"] = params["checklist_items"].join("\n") if params["checklist_items"]
      url_params["list-id"] = params["list_id"] if params["list_id"]
      url_params["list"] = params["list_title"] if params["list_title"]
      url_params["heading"] = params["heading"] if params["heading"]

      execute_url("#{THINGS_URL_BASE}add", url_params)
    end

    def add_project(params)
      url_params = {
        "title" => params["title"],
        "type" => "project",
      }

      # Optional parameters
      url_params["notes"] = params["notes"] if params["notes"]
      url_params["when"] = params["when"] if params["when"]
      url_params["deadline"] = params["deadline"] if params["deadline"]
      url_params["tags"] = params["tags"].join(",") if params["tags"]
      url_params["area-id"] = params["area_id"] if params["area_id"]
      url_params["area"] = params["area_title"] if params["area_title"]
      url_params["to-dos"] = params["todos"].join("\n") if params["todos"]

      execute_url("#{THINGS_URL_BASE}add-project", url_params)
    end

    def update_todo(params)
      url_params = {
        "id" => params["id"],
      }

      # Optional update parameters
      url_params["title"] = params["title"] if params["title"]
      url_params["notes"] = params["notes"] if params["notes"]
      url_params["when"] = params["when"] if params["when"]
      url_params["deadline"] = params["deadline"] if params["deadline"]
      # Use add-tags to append tags (might work better for new tags)
      url_params["add-tags"] = params["tags"].join(",") if params["tags"]
      url_params["completed"] = "true" if params["completed"]
      url_params["canceled"] = "true" if params["canceled"]

      execute_url("#{THINGS_URL_BASE}update", url_params)
    end

    def update_project(params)
      url_params = {
        "id" => params["id"],
        "type" => "project",
      }

      # Optional update parameters
      url_params["title"] = params["title"] if params["title"]
      url_params["notes"] = params["notes"] if params["notes"]
      url_params["when"] = params["when"] if params["when"]
      url_params["deadline"] = params["deadline"] if params["deadline"]
      url_params["tags"] = params["tags"].join(",") if params["tags"]
      url_params["completed"] = "true" if params["completed"]
      url_params["canceled"] = "true" if params["canceled"]

      execute_url("#{THINGS_URL_BASE}update-project", url_params)
    end

    def search_items(query)
      execute_url("#{THINGS_URL_BASE}search", { "query" => query })
    end

    def show_item(params)
      url_params = {
        "id" => params["id"],
      }

      url_params["query"] = params["query"] if params["query"]
      url_params["filter"] = params["filter_tags"].join(",") if params["filter_tags"]

      execute_url("#{THINGS_URL_BASE}show", url_params)
    end

    private

    def execute_url(base_url, params = {})
      # Add auth token for operations that require it
      if needs_auth_token?(base_url) && ENV["THINGS_AUTH_TOKEN"]
        params["auth-token"] = ENV["THINGS_AUTH_TOKEN"]
      end

      # Build query string and convert + to %20 for spaces
      query_string = URI.encode_www_form(params)
      query_string = query_string.gsub("+", "%20") unless query_string.empty?
      
      full_url = query_string.empty? ? base_url : "#{base_url}?#{query_string}"


      # Ensure Things is running
      unless things_running?
        launch_things
        sleep(2)
      end

      # Open the URL
      _, stderr, status = Open3.capture3("open", full_url)

      if status.success?
        { success: true }
      else
        { success: false, error: stderr }
      end
    rescue => e
      { success: false, error: e.message }
    end

    def things_running?
      system('pgrep -x "Things3" > /dev/null 2>&1')
    end

    def launch_things
      system("open -a Things3")
    end

    def needs_auth_token?(url)
      # Operations that require authentication token
      auth_required_operations = [
        "things:///update",
        "things:///update-project",
      ]

      auth_required_operations.any? { |op| url.start_with?(op) }
    end

  end
end
