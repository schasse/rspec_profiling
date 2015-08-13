require 'smarter_csv'
require 'awesome_print'
require 'pry'

def stats
  @stats ||= SmarterCSV.process('tmp/spec_benchmark1')
end

def stats_grouped_by_file
  @stats_grouped_by_file ||= stats.group_by { |stat| stat[:file] }
end

def worst(property)
  stats.sort { |stat1, stat2| stat2[property] <=> stat1[property] }
end

def grouped_by_file_worst(property)
  stats_grouped_by_file.map do |file, stats|
    [file, stats.reduce(0) { |sum, stat| sum + stat[property].to_f }.round(2)]
  end.
    sort { |stat1, stat2| stat2.last <=> stat1.last }.
    map { |stat| stat.join(' ') }
end

# worst time
ap worst(:time)[0..20]

# worst query_time
ap worst(:query_time)[0..20]
ap worst(:moped_time)[0..20]

# group by file
#  * worst time
ap grouped_by_file_worst(:time)[0..20]

#  * worst query_time
ap grouped_by_file_worst(:query_time)[0..20]
ap grouped_by_file_worst(:moped_time)[0..20]

# similar queries
binding.pry
