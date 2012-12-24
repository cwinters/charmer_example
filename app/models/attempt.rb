class Attempt < ActiveRecord::Base
  include ShardedModel

  db_magic :sharded => {
      key: :classroom_id, sharded_connection: :enrollments
  }

  attr_accessible :correct, :classroom_id, :lesson_id, :response, :user_id

  belongs_to :classroom
  belongs_to_in_shard :lesson
  belongs_to :user

  before_create :assign_shard_id

  def sequence_name
    'shard_seq_attempt'
  end
end