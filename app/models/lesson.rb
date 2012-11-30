class Lesson < ActiveRecord::Base
  db_magic :sharded => {
      key: :classroom_id, sharded_connection: :enrollments
  }

  before_create :assign_shard_id

  attr_accessible :classroom_id, :enrollment_id, :name
  belongs_to :classroom
  belongs_to :enrollment
  has_many :attempts

  def assign_shard_id
    self.id = School.connection.select_value( "SELECT NEXTVAL( 'shard_seq_lesson' )")
  end
end
