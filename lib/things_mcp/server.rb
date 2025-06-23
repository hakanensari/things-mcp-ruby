# frozen_string_literal: true

require "mcp"
require "mcp/transports/stdio"
require "logger"
require_relative "tools"
require_relative "handlers"
require_relative "database"
require_relative "url_scheme"

module ThingsMcp
  # MCP server implementation for Things 3 integration
  #
  # This class creates and runs an MCP server that provides tools for interacting with Things 3. It sets up tool
  # definitions, handles tool calls, and manages the stdio transport.
  class Server
    def initialize
      # Check Ruby version first
      check_ruby_version

      @logger = Logger.new($stderr)
      @logger.level = Logger::INFO

      # Create all tool classes
      create_tool_classes

      @server = MCP::Server.new(
        name: "things",
        version: "0.1.0",
        tools: @tool_classes,
      )
    rescue => e
      $stderr.puts "ERROR during initialization: #{e.class}: #{e.message}"
      $stderr.puts "Backtrace:"
      e.backtrace.each { |line| $stderr.puts "  #{line}" }
      $stderr.flush
      raise
    end

    def run
      @logger.info("Starting Things MCP server...")

      # Check if Things app is available
      unless ThingsMcp::Database.things_app_available?
        @logger.warn("Things app is not running. Will attempt to launch when needed.")
      end

      # Run the server using stdio
      transport = MCP::Transports::StdioTransport.new(@server)
      transport.open
    rescue => e
      # Output to stderr so Claude can see the error
      $stderr.puts "ERROR: #{e.class}: #{e.message}"
      $stderr.puts "Backtrace:"
      e.backtrace.each { |line| $stderr.puts "  #{line}" }
      $stderr.flush
      raise
    end

    private

    def check_ruby_version
      required_version = Gem::Version.new("3.2.0")
      current_version = Gem::Version.new(RUBY_VERSION)

      return if current_version >= required_version

      $stderr.puts "❌ Ruby #{RUBY_VERSION} is too old! This server requires Ruby 3.2+"
      $stderr.flush
      exit(1)
    end

    def create_tool_classes
      @tool_classes = []

      # Create a tool class for each tool definition
      ThingsMcp::Tools.all.each do |tool_def|
        tool_class = create_tool_class(tool_def)
        @tool_classes << tool_class
      end

      @logger.info("Created #{@tool_classes.size} tool classes")
    end

    def create_tool_class(tool_def)
      name = tool_def[:name]

      Class.new(MCP::Tool) do
        tool_name name
        description tool_def[:description]

        input_schema(
          type: tool_def[:inputSchema][:type],
          properties: tool_def[:inputSchema][:properties],
          required: tool_def[:inputSchema][:required],
        )

        define_singleton_method(:call) do |_server_context:, **arguments|
          # Convert symbol keys to string keys for consistent access
          string_arguments = arguments.transform_keys(&:to_s)
          result = ThingsMcp::Handlers.handle_tool_call(name, string_arguments)

          MCP::Tool::Response.new([
            {
              type: "text",
              text: result,
            },
          ])
        rescue => e
          MCP::Tool::Response.new([
            {
              type: "text",
              text: "Error: #{e.message}",
            },
          ])
        end
      end
    end
  end
end
