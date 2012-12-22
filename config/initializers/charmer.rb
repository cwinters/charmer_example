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

ActiveSupport.on_load(:active_record) do

# add some helpful methods to the association proxy -- DbCharmer does this itself
# in db_charmer.rb lines 150-184
  ActiveRecord::Associations::CollectionProxy.class_exec do

    def current_shard
      shard_name = RequestStore.store[:shard_name]
      if shard_name
        puts "CharmerExample.current_shard [Value: #{shard_name}]"
        on_db(@association.owner.sharded_connection.sharder.shard_for_key(shard_name))
      else
        on_db(@association.owner.db_charmer_connection_proxy) # ?!@>#? where is 'my current connection' stored in the object?
      end
    end

# CMW added as a higher level 'on_db'
    def on_classroom(classroom_id, proxy_target = nil, &block)
      puts "CharmerExample.on_classroom [Classroom ID: #{classroom_id}] [Proxy target nil? #{proxy_target.nil?}]"
      on_db(conn_for_classroom(classroom_id), proxy_target, &block)
    end

# CMW added as a higher level 'on_db'
    def conn_for_classroom(classroom_id)
      idx = classroom_id.to_i % CharmerExample::Application.config.shards.length
      shard_name = CharmerExample::Application.config.shards[idx]
      puts "CharmerExample.conn_for_classroom [Classroom ID: #{classroom_id}] % [Shard length: #{CharmerExample::Application.config.shards.length}] => [Index: #{idx}] => [Shard: #{shard_name}] "
      sharded_connection.sharder.shard_for_key(shard_name)
    end
  end

  module DbCharmer
    module ActiveRecord
      module Sharding
        def current_shard
          shard_name = RequestStore.store[:shard_name]
          if shard_name
            puts "#{self}.current_shard [Value: #{shard_name}]"
            on_db(self.sharded_connection.sharder.shard_for_key(shard_name))
          else
            puts "#{self}.current_shard - NO current_shard value, what to do?!"
            on_db(self.db_charmer_connection_proxy) # ?!@>#? where is 'my current connection' stored in the object?
          end
        end
      end
    end
  end
end