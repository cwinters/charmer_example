class Lesson < ActiveRecord::Base
  include ShardedModel

  db_magic :sharded => {
      key: :classroom_id, sharded_connection: :enrollments
  }

  attr_accessible :classroom_id, :enrollment_id, :name
  belongs_to :classroom
  belongs_to_in_shard :enrollment
  has_many_in_shard :attempts

  before_create :assign_shard_id

  def sequence_name
    'shard_seq_lesson'
  end
end
