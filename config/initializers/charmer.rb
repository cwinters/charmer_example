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

# add some helpful methods to the association proxy that allow us to find the connection to use;
# DbCharmer does something similar in db_charmer.rb lines 150-184
  ActiveRecord::Associations::CollectionProxy.class_exec do

    def current_shard
      real_connection = @association.owner.connection.real_conn
      if real_connection
        puts "Association owner provided real connection! [Owner: #{@association.owner.class.to_s}@#{@association.owner.id}]"
        on_db(real_connection)
      end
      shard_name = RequestStore.store && RequestStore.store[:shard_name]
      if shard_name
        puts "CharmerExample.current_shard [Value: #{shard_name}]"
        on_db(@association.owner.sharded_connection.sharder.shard_for_key(shard_name))
      else
        raise ::ActiveRecord::ConnectionNotEstablished, "Association owner has no connection (?!), so define RequestStore.store[:shard_name] to set the current shard"
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

  # This defines a CLASS method to find the current shard; it uses either the given connection or the
  # shard defined by the global-ish 'shard_name' variable. Otherwise it throws an error.
  module DbCharmer
    module ActiveRecord
      module Sharding
        def current_shard(conn = nil)
          return on_db(conn) if conn
          shard_name = RequestStore.store && RequestStore.store[:shard_name]
          if shard_name
            puts "#{self}.current_shard [Value: #{shard_name}]"
            return on_db(self.sharded_connection.sharder.shard_for_key(shard_name))
          else
            raise ::ActiveRecord::ConnectionNotEstablished, "Define RequestStore.store[:shard_name] to set the current shard"
          end
        end
      end
    end
  end

  # inject our '_in_shard' versions of associations
  require 'shard_association_shortcuts'
  ActiveRecord::Base.send(:include, ShardAssociationShortcuts::ActiveRecord)

  # add a attribute accessor so we can directly grab the real connection at runtime
  DbCharmer::Sharding::StubConnection.class_exec do
    attr_accessor :real_conn
  end

end