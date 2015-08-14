require 'smarter_csv'
require 'awesome_print'

module RspecProfiling
  class ProfilingStats
    def dump
      File.open(RspecProfiling.config.stats_path.call, 'w') do |f|
        f.write('######################### worst time' +
          worst(:time)[0..20].ai +

          '######################### worst query_time' +
          worst(:query_time)[0..20].ai +
          worst(:moped_time)[0..20].ai +

          '######################### group by file' +
          '#########################  * worst time' +
          grouped_by_file_worst(:time)[0..20].ai +

          '#########################  * worst query_time' +
          grouped_by_file_worst(:query_time)[0..20].ai +
          grouped_by_file_worst(:moped_time)[0..20].ai)
      end
    end

    private

    def stats
      @stats ||= SmarterCSV.process(RspecProfiling.config.csv_path.call)
    end

    def stats_grouped_by_file
      @stats_grouped_by_file ||= stats.group_by { |stat| stat[:file] }
    end

    def worst(property)
      # sort by property, p.e. time
      stats.sort { |stat1, stat2| stat2[property] <=> stat1[property] }
    end

    def grouped_by_file_worst(property)
      stats_grouped_by_file.map do |file, stats|
        [
          file,
          # aggregate property, p.e. time per file
          stats.reduce(0) { |sum, stat| sum + stat[property].to_f }.round(2)
        ]
      end.
        # sort by aggregated property, p.e. time
        sort { |stat1, stat2| stat2.last <=> stat1.last }.
        map { |stat| stat.join(' ') }
    end
  end
end
