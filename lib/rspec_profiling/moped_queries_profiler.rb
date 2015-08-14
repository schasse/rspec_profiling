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
        File.open(RspecProfiling.config.moped_queries_path.call, 'w') do |f|
          f.write(
            queries
              .sort { |q1, q2| q2.last <=> q1.last } # sort by time
              .take(200) # dump only 200 slowest
              .map { |query, time| "#{query} (#{time}s)" }
              .join("\n"))
        end
      end
    end
  end
end
