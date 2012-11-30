SHARDING_MAP = {
    '1' => :shard_one,
    '2' => :shard_two,
    '3' => :shard_three,
    '4' => :shard_four,
    '5' => :shard_one,
    '6' => :shard_two,
    '7' => :shard_three,
    '8' => :shard_four,
    :default => :shard_four
}

DbCharmer::Sharding.register_connection(
    :name   => :enrollments,
    :method => :hash_map,
    :map    => SHARDING_MAP
)


#    :method       => :db_block_map,
#    :block_size   => 10000,                    # Number of keys per block
#    :map_table    => :enrollment_shards_map,   # Table with blocks to shards mapping
#    :shards_table => :enrollment_shards_info,  # Shards connection information table
#    :connection   => :master                   # What connection to use to read the map
#)


