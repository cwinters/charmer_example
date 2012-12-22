class Lesson < ActiveRecord::Base
  include ShardedModel

  db_magic :sharded => {
      key: :classroom_id, sharded_connection: :enrollments
  }

  attr_accessible :classroom_id, :enrollment_id, :name
  belongs_to :classroom
  belongs_to :enrollment
  has_many :attempts

  before_create :assign_shard_id

  def attempts
    super.current_shard
  end

  def enrollment
    Enrollment.current_shard.find(self.enrollment_id)
  end

  def sequence_name
    'shard_seq_lesson'
  end
end
