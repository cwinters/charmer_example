module ShardedModel

  def self.shard_for(key)
    conn = sharded_connection.sharder.shard_for_key(key)
    on_db(conn, nil)
  end

  def self.shard_for_classroom(classroom_id)
    shard_for(shard_name(classroom_id))
  end

  def self.shard_name(id)
    idx = id.to_i % CharmerExample::Application.config.shards.length
    shard_name = CharmerExample::Application.config.shards[idx]
    puts "#{self.class.to_s}.shard_name: [Classroom ID #{id}] % [Shard length: #{CharmerExample::Application.config.shards.length}] => [Index #{idx}] => [Shard #{shard_name}] "
    shard_name
  end

  def assign_shard_id
     self.id = School.connection.select_value( "SELECT NEXTVAL('#{self.sequence_name}')")
  end

  def shard_for(key)
    ShardedModel.shard_for(key)
  end

  def shard_for_classroom(classroom_id)
    ShardedModel.shard_for_classroom(classroom_id)
  end

  def shard_name(id)
    ShardedModel.shard_name(id)
  end
end