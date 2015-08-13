require "rspec_profiling/example"
require "rspec_profiling/vcs/git"
require "rspec_profiling/vcs/svn"
require "rspec_profiling/vcs/git_svn"
require "rspec_profiling/collectors/sql"
require "rspec_profiling/collectors/psql"
require "rspec_profiling/collectors/csv"

module RspecProfiling
  class Run
    def initialize(collector = RspecProfiling.config.collector.new,
                   vcs = RspecProfiling.config.vcs.new)

      @collector = collector
      @vcs       = vcs
    end

    def start(*args)
      start_counting_queries
      start_counting_requests
    end

    def example_started(example)
      example = example.example if example.respond_to?(:example)
      Thread.current['current_example'] = @current_example = Example.new(example)
    end

    def example_finished(*args)
      collector.insert({
        commit:        vcs.sha,
        date:          vcs.time,
        file:          @current_example.file,
        line_number:   @current_example.line_number,
        description:   @current_example.description,
        status:        @current_example.status,
        exception:     @current_example.exception,
        time:          @current_example.time,
        query_count:   @current_example.query_count,
        query_time:    @current_example.query_time,
        moped_count:   @current_example.moped_count,
        moped_time:    @current_example.moped_time,
        request_count: @current_example.request_count,
        request_time:  @current_example.request_time
      })
    end

    alias :example_passed :example_finished
    alias :example_failed :example_finished

    private

    attr_reader :collector, :vcs

    def start_counting_queries
      ActiveSupport::Notifications.subscribe("sql.active_record") do |name, start, finish, id, query|
        @current_example.try(:log_query, query, start, finish)
      end

      ::Moped::Node.class_eval do
        private

        def logging_with_profiling(operations, &block)
          all_queries = Thread.current['all_queries'] ||= {}
          start = Time.now.to_f
          output = logging_without_profiling(operations, &block)
          stop = Time.now.to_f
          Thread.current['current_example'].try(:log_moped, nil, start, stop)
          query = operations.first.log_inspect
          all_queries[query] = (all_queries[query] || 0) + stop - start
          output
        end

        alias_method :logging_without_profiling, :logging
        alias_method :logging, :logging_with_profiling
      end
    end

    def start_counting_requests
      ActiveSupport::Notifications.subscribe("process_action.action_controller") do |name, start, finish, id, request|
        @current_example.try(:log_request, request, start, finish)
      end
    end
  end
end

if Rails.env.test? && RSpec.methods.include?(:configure)
  RSpec.configure do |config|
    config.after(:suite) do
      all_queries_file_content =
        Thread
        .current['all_queries']
        .sort { |q1, q2| q2.last <=> q1.last } # sort by time
        .map { |query, time| "#{query} (#{time}s)" }
        .join("\n")
      File.open(RspecProfiling.config.csv_path.call + 'queries', 'w') do |f|
        f.write all_queries_file_content
      end
    end
  end
end
