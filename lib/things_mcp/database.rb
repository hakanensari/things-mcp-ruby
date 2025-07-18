# frozen_string_literal: true

require "sqlite3"
require "pathname"
require "date"
require "uri"

module ThingsMcp
  # Database access layer for Things 3 SQLite database
  #
  # This class provides read-only access to the Things 3 database, enabling retrieval of todos, projects, areas, and
  # tags. It handles dynamic database path resolution and provides formatted data structures.
  class Database
    # Things date encoding constants
    UNITS_PER_DAY = 128.0
    EPOCH = Date.new(-814, 4, 1)

    class << self
      def database_path
        @database_path ||= find_database_path
      end

      def things_app_available?
        system('pgrep -x "Things3" > /dev/null 2>&1')
      end

      def with_database(&block)
        db_path = database_path
        unless db_path
          raise "Things database not found. Please ensure Things 3 is installed and has been launched at least once."
        end

        db = SQLite3::Database.new(db_path, readonly: true)
        db.results_as_hash = true
        yield db
      ensure
        db&.close
      end

      # Get all todos
      def get_todos(project_uuid: nil, include_items: true)
        with_database do |db|
          query = build_todo_query(project_uuid: project_uuid)
          results = db.execute(query)

          todos = results.map { |row| format_todo(row) }

          if include_items
            todos.each do |todo|
              todo[:checklist_items] = get_checklist_items(db, todo[:uuid])
            end
          end

          # Always fetch tags for todos
          todos.each do |todo|
            todo[:tags] = get_tags_for_task(db, todo[:uuid])
          end

          todos
        end
      end

      # Get todos from specific lists
      def get_inbox
        get_todos_by_start(0)
      end

      def get_today
        # Get todos scheduled for today or overdue (startDate <= today's value)
        today_value = (Date.today - EPOCH) * UNITS_PER_DAY

        with_database do |db|
          query = <<~SQL
            SELECT #{todo_columns}
            FROM TMTask
            WHERE type = 0
              AND status = 0
              AND trashed = 0
              AND startDate IS NOT NULL
              AND startDate <= #{today_value.to_i}
            ORDER BY "index"
          SQL

          results = db.execute(query).map { |row| format_todo(row) }
          add_checklist_items_and_tags(db, results)
        end
      end

      def get_upcoming
        with_database do |db|
          query = <<~SQL
            SELECT #{todo_columns}
            FROM TMTask
            WHERE type = 0
              AND status = 0
              AND trashed = 0
              AND start = 2
              AND (startDate IS NOT NULL OR deadline IS NOT NULL)
            ORDER BY COALESCE(startDate, deadline)
          SQL

          results = db.execute(query).map { |row| format_todo(row) }
          add_checklist_items_and_tags(db, results)
        end
      end

      def get_anytime
        with_database do |db|
          query = <<~SQL
            SELECT #{todo_columns}
            FROM TMTask
            WHERE type = 0
              AND status = 0
              AND trashed = 0
              AND start = 1
            ORDER BY "index"
          SQL

          results = db.execute(query).map { |row| format_todo(row) }
          add_checklist_items_and_tags(db, results)
        end
      end

      def get_someday
        # Get todos in someday: start=2 with no dates
        # FIXME: Recurring items (like "Update mileage log") appear here when they should
        # appear in Today or Scheduled based on their next occurrence. Things likely uses
        # additional metadata to track recurring patterns that we haven't implemented.
        with_database do |db|
          query = <<~SQL
            SELECT #{todo_columns}
            FROM TMTask
            WHERE type = 0
              AND status = 0
              AND trashed = 0
              AND start = 2
              AND startDate IS NULL
              AND deadline IS NULL
            ORDER BY "index"
          SQL

          results = db.execute(query).map { |row| format_todo(row) }
          add_checklist_items_and_tags(db, results)
        end
      end

      def get_logbook(period: "7d", limit: 50)
        days = parse_period(period)
        cutoff = Date.today - days
        # stopDate is a REAL column with Unix timestamp
        cutoff_timestamp = cutoff.to_time.to_i

        with_database do |db|
          query = <<~SQL
            SELECT #{todo_columns}
            FROM TMTask
            WHERE type = 0
              AND status IN (3, 2)
              AND trashed = 0
              AND stopDate >= #{cutoff_timestamp}
            ORDER BY stopDate DESC
            LIMIT #{limit}
          SQL

          db.execute(query).map { |row| format_todo(row) }
        end
      end

      def get_trash
        with_database do |db|
          query = <<~SQL
            SELECT #{todo_columns}
            FROM TMTask
            WHERE type = 0
              AND trashed = 1
            ORDER BY userModificationDate DESC
          SQL

          db.execute(query).map { |row| format_todo(row) }
        end
      end

      # Get projects
      def get_projects(include_items: false)
        with_database do |db|
          query = <<~SQL
            SELECT uuid, title, notes, status, area, start, startDate, deadline,
                   creationDate, userModificationDate
            FROM TMTask
            WHERE type = 1
              AND trashed = 0
            ORDER BY userModificationDate DESC
          SQL

          projects = db.execute(query).map { |row| format_project(row) }

          if include_items
            projects.each do |project|
              project[:todos] = get_todos(project_uuid: project[:uuid])
            end
          end

          projects
        end
      end

      # Get areas
      def get_areas(include_items: false)
        with_database do |db|
          query = <<~SQL
            SELECT uuid, title, tags
            FROM TMArea
            ORDER BY "index"
          SQL

          areas = db.execute(query).map { |row| format_area(row) }

          if include_items
            areas.each do |area|
              # Get projects in this area
              project_query = <<~SQL
                SELECT uuid, title
                FROM TMTask
                WHERE type = 1
                  AND trashed = 0
                  AND area = '#{area[:uuid]}'
              SQL

              area[:projects] = db.execute(project_query).map do |proj|
                { uuid: proj["uuid"], title: proj["title"] }
              end
            end
          end

          areas
        end
      end

      # Get tags
      def get_tags(include_items: false)
        with_database do |db|
          query = "SELECT uuid, title FROM TMTag ORDER BY title"

          tags = db.execute(query).map { |row| format_tag(row) }

          if include_items
            tags.each do |tag|
              tag[:items] = get_tagged_items(tag[:title])
            end
          end

          tags
        end
      end

      def get_tagged_items(tag_title)
        with_database do |db|
          # Find tag UUID
          tag_result = db.execute("SELECT uuid FROM TMTag WHERE title = ?", [tag_title]).first
          return [] unless tag_result

          tag_uuid = tag_result["uuid"]

          query = <<~SQL
            SELECT #{todo_columns}
            FROM TMTask
            WHERE type = 0
              AND status = 0
              AND trashed = 0
              AND tags LIKE '%#{tag_uuid}%'
            ORDER BY userModificationDate DESC
          SQL

          db.execute(query).map { |row| format_todo(row) }
        end
      end

      # Search todos
      def search_todos(query)
        with_database do |db|
          search_query = <<~SQL
            SELECT #{todo_columns}
            FROM TMTask
            WHERE type = 0
              AND trashed = 0
              AND (title LIKE '%#{query}%' OR notes LIKE '%#{query}%')
            ORDER BY userModificationDate DESC
          SQL

          db.execute(search_query).map { |row| format_todo(row) }
        end
      end

      def search_advanced(filters = {})
        with_database do |db|
          conditions = ["type = 0", "trashed = 0"]

          # Status filter
          if filters[:status]
            status_map = { "incomplete" => 0, "completed" => 3, "canceled" => 2 }
            conditions << "status = #{status_map[filters[:status]]}"
          end

          # Date filters
          if filters[:start_date]
            # startDate is INTEGER column with NSDate seconds
            nsdate_epoch = Time.new(2001, 1, 1, 0, 0, 0, "+00:00")
            start_timestamp = (Date.parse(filters[:start_date]).to_time - nsdate_epoch).to_i
            conditions << "startDate >= #{start_timestamp}"
          end

          if filters[:deadline]
            # deadline is INTEGER column with NSDate seconds
            nsdate_epoch = Time.new(2001, 1, 1, 0, 0, 0, "+00:00")
            deadline_timestamp = (Date.parse(filters[:deadline]).to_time - nsdate_epoch).to_i
            conditions << "deadline <= #{deadline_timestamp}"
          end

          # Tag filter
          if filters[:tag]
            tag_result = db.execute("SELECT uuid FROM TMTag WHERE title = ?", [filters[:tag]]).first
            conditions << "tags LIKE '%#{tag_result["uuid"]}%'" if tag_result
          end

          # Area filter
          if filters[:area]
            conditions << "area = '#{filters[:area]}'"
          end

          # Type filter
          if filters[:type]
            type_map = { "to-do" => 0, "project" => 1, "heading" => 2 }
            conditions << "type = #{type_map[filters[:type]]}"
          end

          query = <<~SQL
            SELECT #{todo_columns}
            FROM TMTask
            WHERE #{conditions.join(" AND ")}
            ORDER BY userModificationDate DESC
          SQL

          db.execute(query).map { |row| format_todo(row) }
        end
      end

      def get_recent(period)
        days = parse_period(period)
        cutoff = Date.today - days
        # creationDate is a REAL column with Unix timestamp
        cutoff_timestamp = cutoff.to_time.to_i

        with_database do |db|
          query = <<~SQL
            SELECT #{todo_columns}
            FROM TMTask
            WHERE type = 0
              AND trashed = 0
              AND creationDate >= #{cutoff_timestamp}
            ORDER BY creationDate DESC
          SQL

          db.execute(query).map { |row| format_todo(row) }
        end
      end

      private

      def find_database_path
        # Use actual user's home directory, not the process owner's
        actual_home = ENV["HOME"] || Dir.home
        # If running as root, try to find the real user's home directory
        if actual_home == "/var/root" && ENV["SUDO_USER"]
          actual_home = "/Users/#{ENV["SUDO_USER"]}"
        elsif actual_home == "/var/root"
          # Fallback: look for the most recent user directory
          user_dirs = Dir.glob("/Users/*").select { |d| File.directory?(d) && !File.basename(d).start_with?(".") }
          actual_home = user_dirs.max_by { |d| File.mtime(d) } if user_dirs.any?
        end

        group_containers_dir = "#{actual_home}/Library/Group Containers"

        # Find Things-specific directories to avoid permission issues
        things_dirs = Dir.glob("#{group_containers_dir}/*").select do |dir|
          File.basename(dir).include?("culturedcode.ThingsMac")
        end

        things_dirs.each do |things_dir|
          # First try to find the current database (not in Backups folder)
          current_pattern = "#{things_dir}/*/Things Database.thingsdatabase/main.sqlite"
          current_matches = Dir.glob(current_pattern).reject { |path| path.include?("/Backups/") }

          unless current_matches.empty?
            return current_matches.first
          end

          # Fallback: look for any main.sqlite but exclude backups
          fallback_pattern = "#{things_dir}/*/*/main.sqlite"
          fallback_matches = Dir.glob(fallback_pattern).reject { |path| path.include?("/Backups/") }

          unless fallback_matches.empty?
            return fallback_matches.first
          end
        end

        nil
      end

      def todo_columns
        "uuid, title, notes, status, project, area, start, startDate, deadline, creationDate, userModificationDate"
      end

      def build_todo_query(project_uuid: nil)
        base_query = <<~SQL
          SELECT #{todo_columns}
          FROM TMTask
          WHERE type = 0
            AND trashed = 0
        SQL

        base_query += " AND project = '#{project_uuid}'" if project_uuid
        base_query + ' ORDER BY "index"'
      end

      def get_todos_by_start(start_value)
        with_database do |db|
          query = <<~SQL
            SELECT #{todo_columns}
            FROM TMTask
            WHERE type = 0
              AND status = 0
              AND trashed = 0
              AND start = #{start_value}
            ORDER BY "index"
          SQL

          db.execute(query).map { |row| format_todo(row) }
        end
      end

      def get_checklist_items(db, task_uuid)
        query = <<~SQL
          SELECT uuid, title, status
          FROM TMChecklistItem
          WHERE task = '#{task_uuid}'
          ORDER BY "index"
        SQL

        db.execute(query).map do |item|
          {
            uuid: item["uuid"],
            title: item["title"],
            completed: item["status"] == 3,
          }
        end
      end

      def get_tags_for_task(db, task_uuid)
        query = <<~SQL
          SELECT TAG.title
          FROM TMTaskTag AS TASK_TAG
          LEFT OUTER JOIN TMTag TAG ON TAG.uuid = TASK_TAG.tags
          WHERE TASK_TAG.tasks = ?
          ORDER BY TAG."index"
        SQL

        db.execute(query, [task_uuid]).map { |row| row["title"] }.compact
      end

      def format_todo(row)
        {
          uuid: row["uuid"],
          title: decode_title(row["title"]),
          notes: decode_title(row["notes"]),
          status: format_status(row["status"]),
          project: row["project"],
          area: row["area"],
          tags: [],  # Tags will be populated separately
          start: row["start"],
          start_date: things_date_to_date(row["startDate"]),
          deadline: things_date_to_date(row["deadline"]),
          created: unix_timestamp_to_date(row["creationDate"]),
          modified: unix_timestamp_to_date(row["userModificationDate"]),
        }
      end

      def format_project(row)
        {
          uuid: row["uuid"],
          title: decode_title(row["title"]),
          notes: decode_title(row["notes"]),
          status: format_status(row["status"]),
          area: row["area"],
          tags: [],  # Tags will be populated separately for projects too
          start: row["start"],
          start_date: things_date_to_date(row["startDate"]),
          deadline: things_date_to_date(row["deadline"]),
          created: unix_timestamp_to_date(row["creationDate"]),
          modified: unix_timestamp_to_date(row["userModificationDate"]),
        }
      end

      def format_area(row)
        {
          uuid: row["uuid"],
          title: row["title"],
          tags: [], # Areas can have tags but we'll implement that separately if needed
        }
      end

      def format_tag(row)
        {
          uuid: row["uuid"],
          title: row["title"],
        }
      end

      def format_status(status)
        case status
        when 0 then "incomplete"
        when 2 then "canceled"
        when 3 then "completed"
        else "unknown"
        end
      end

      def things_date_to_date(value)
        return unless value

        # Things uses custom date encoding: 128 units = 1 day (11.25 minutes per unit)
        # Epoch calculated from reverse engineering known date values
        days = value / UNITS_PER_DAY
        (EPOCH + days).to_s
      end

      def unix_timestamp_to_date(value)
        return unless value

        # REAL columns (creationDate, userModificationDate): Unix timestamps (seconds since 1970-01-01)
        Time.at(value.to_f).to_date.to_s
      end

      def parse_period(period)
        match = period.match(/^(\d+)([dwmy])$/)
        raise ArgumentError, "Invalid period format: #{period}" unless match

        number = match[1].to_i
        unit = match[2]

        case unit
        when "d" then number
        when "w" then number * 7
        when "m" then number * 30
        when "y" then number * 365
        end
      end

      def decode_title(title)
        return unless title

        # Decode URL-encoded titles that may come from URL scheme operations
        URI.decode_www_form_component(title.to_s)
      rescue
        # If decoding fails, return original title
        title
      end

      # Helper method to consistently add checklist items and tags to todos
      def add_checklist_items_and_tags(db, todos)
        todos.each do |todo|
          todo[:checklist_items] = get_checklist_items(db, todo[:uuid])
          todo[:tags] = get_tags_for_task(db, todo[:uuid])
        end
        todos
      end
    end
  end
end
