require 'ultralite'
require 'active_record'
require 'active_record/connection_adapters/sqlite3_adapter'

module ActiveRecord

	module ConnectionHandling # :nodoc:

		def ultralite_connection(config)

			config = config.symbolize_keys

			# Require database.
			unless config[:database]
				raise ArgumentError, "No database file specified. Missing argument: database"
			end

			# Allow database path relative to Rails.root, but only if the database
			# path is not the special path that tells sqlite to build a database only
			# in memory.
			if ":memory:" != config[:database] && !config[:database].to_s.start_with?("file:")
				config[:database] = File.expand_path(config[:database], Rails.root) if defined?(Rails.root)
				dirname = File.dirname(config[:database])
				Dir.mkdir(dirname) unless File.directory?(dirname)
			end

			db = Ultralite::DB.new(
				config[:database].to_s,
				config.merge(results_as_hash: true)
			)

			ConnectionAdapters::UltraliteAdapter.new(db, logger, nil, config)
			
		rescue Errno::ENOENT => error
			if error.message.include?("No such file or directory")
				raise ActiveRecord::NoDatabaseError
			else
				raise
			end
		end
	end

	module ConnectionAdapters # :nodoc:

		class UltraliteAdapter < SQLite3Adapter
		  ADAPTER_NAME = "Ultralite"
		end
		
		private
		
	    def connect
          @raw_connection = ::Ultralite::DB.new(
            @config[:database].to_s,
            @config.merge(results_as_hash: true)
          )
          configure_connection
        end

	end
	
end
