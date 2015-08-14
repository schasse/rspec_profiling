module RspecProfiling
  def self.configure
    yield config
  end

  def self.path_builder(name)
    lambda do
      if ENV['CIRCLE_ARTIFACTS']
        File.join(
          '..', '..', '..', ENV['CIRCLE_ARTIFACTS'], "profiling_#{name}.csv")
      else
        "tmp/profiling_#{name}_#{Time.now.to_i}.csv"
      end
    end
  end

  def self.config
    @config ||= OpenStruct.new(
      vcs: RspecProfiling::VCS::Git,
      collector: RspecProfiling::Collectors::CSV,
      csv_path: path_builder('benchmark'),
      stats_path: path_builder('stats'),
      moped_queries_path: path_builder('moped_queries'))
  end
end
