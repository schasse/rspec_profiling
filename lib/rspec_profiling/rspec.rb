require "rspec_profiling"

RSpec.configure do |config|
  runner = RspecProfiling::Run.new(RspecProfiling.config.collector.new,
                                   RspecProfiling.config.vcs.new)

  config.reporter.register_listener(
    runner,
    :start,
    :example_started,
    :example_passed,
    :example_failed
  )

  config.after(:suite) do
    runner.collector.output.close # flush collector output, we need it now
    RspecProfiling::MopedQueriesProfiler.dump
    RspecProfiling::ProfilingStats.new.dump
  end
end
