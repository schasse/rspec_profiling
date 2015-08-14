module RspecProfiling
  class MopedQueriesProfiler
    class << self
      def queries
        Thread.current['rspec_profiling_moped_queries'] ||= {}
      end

      def log(operations, start, stop)
        query = operations.first.log_inspect
        queries[query] = (queries[query] || 0) + stop - start
      end

      def dump
        all_queries_file_content =
          queries
          .sort { |q1, q2| q2.last <=> q1.last } # sort by time
          .take(200) # dump only 200 slowest
          .map { |query, time| "#{query} (#{time}s)" }
          .join("\n")
        File.open(RspecProfiling.config.csv_path.call + 'queries', 'w') do |f|
          f.write all_queries_file_content
        end
      end
    end
  end

  if Rails.env.test? && RSpec.methods.include?(:configure)
    RSpec.configure do |config|
      config.after(:suite) do
        MopedQueriesProfiler.dump
      end
    end
  end
end
