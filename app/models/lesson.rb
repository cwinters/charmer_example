class Lesson < ActiveRecord::Base
  include ShardedModel

  db_magic :sharded => {
      key: :classroom_id, sharded_connection: :enrollments
  }

  before_create :assign_shard_id

  attr_accessible :classroom_id, :enrollment_id, :name
  belongs_to :classroom
  belongs_to :enrollment
  has_many :attempts

  def attempts
    super.on_db(shard_name(self.classroom_id))
  end

  def enrollment
    puts "lesson.enrollment [ID: #{self.id}] [Classroom: #{self.classroom_id}]"
    Enrollment.on_db(shard_name(self.classroom_id)).find(self.enrollment_id)
  end

  def assign_shard_id
    self.id = School.connection.select_value( "SELECT NEXTVAL( 'shard_seq_lesson' )")
  end
end
