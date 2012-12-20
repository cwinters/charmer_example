class CreateShardSequences < ActiveRecord::Migration
  SEQUENCES = %w{ shard_seq_attempt shard_seq_enrollment shard_seq_lesson }
  def up
    SEQUENCES.each {|sequence_name| execute "CREATE SEQUENCE #{sequence_name}"}
  end

  def down
    SEQUENCES.each {|sequence_name| execute "DROP SEQUENCE #{sequence_name}"}
  end
end
