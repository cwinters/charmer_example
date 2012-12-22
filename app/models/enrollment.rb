class Enrollment < ActiveRecord::Base
  include ShardedModel

  db_magic :sharded => {
      key: :classroom_id, sharded_connection: :enrollments
  }

  attr_accessible :classroom_id, :name, :user_id

  belongs_to :classroom
  belongs_to :user
  has_many :lessons

  before_create :assign_shard_id

  def lessons
    super.current_shard
  end

  def full_name
    "#{user.login} in #{classroom.name}: #{name}"
  end

  def sequence_name
    'shard_seq_enrollment'
  end
end
