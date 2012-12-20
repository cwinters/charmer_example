class Attempt < ActiveRecord::Base
  include ShardedModel

  db_magic :sharded => {
      key: :classroom_id, sharded_connection: :enrollments
  }

  before_create :assign_shard_id

  attr_accessible :correct, :classroom_id, :lesson_id, :response, :user_id

  belongs_to :classroom
  belongs_to :lesson
  belongs_to :user

  def lesson
    super.on_db(shard_name(self.classroom_id))
  end

  def assign_shard_id
    self.id = School.connection.select_value( "SELECT NEXTVAL( 'shard_seq_attempt' )")
  end
end
