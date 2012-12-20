class DbCharmer::Sharding::Method::PerRequest
  def initialize(config)
  end

  def shard_for_key(key)
    if CharmerExample::Application.config.shards.include?(key)
      key
    else
      CharmerExample::Application.config.shards.last
    end
  end

  def support_default_shard?
    true
  end
end

DbCharmer::Sharding.register_connection(
    :name   => :enrollments,
    :method => :per_request
)

CharmerExample::Application.configure do
  # should match names in database.yml
  config.shards = [:enrollments_shard_one, :enrollments_shard_two, :enrollments_shard_three, :enrollments_shard_four]
end

#    :method       => :db_block_map,
#    :block_size   => 10000,                    # Number of keys per block
#    :map_table    => :enrollment_shards_map,   # Table with blocks to shards mapping
#    :shards_table => :enrollment_shards_info,  # Shards connection information table
#    :connection   => :master                   # What connection to use to read the map
#)


