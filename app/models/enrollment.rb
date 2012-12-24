class Enrollment < ActiveRecord::Base
  include ShardedModel

  db_magic :sharded => {
      key: :classroom_id, sharded_connection: :enrollments
  }

  attr_accessible :classroom_id, :name, :user_id

  belongs_to :classroom
  belongs_to :user
  has_many_in_shard :lessons

  before_create :assign_shard_id

  def full_name
    "#{user.login} in #{classroom.name}: #{name}"
  end

  def sequence_name
    'shard_seq_enrollment'
  end
end
