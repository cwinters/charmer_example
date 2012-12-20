module ShardedModel

  def shard_name(id)
    idx = id % CharmerExample::Application.config.shards.length
    shard_name = CharmerExample::Application.config.shards[idx]
    puts "shard_name: [Given #{id}] [Shard #{shard_name}] [Shard length: #{CharmerExample::Application.config.shards.length}]"
    shard_name
  end

  def shard_for(key)
    conn = sharded_connection.sharder.shard_for_key(key)
    on_db(conn, nil)
  end
end