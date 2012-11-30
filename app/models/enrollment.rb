class Enrollment < ActiveRecord::Base
  db_magic :sharded => {
      key: :classroom_id, sharded_connection: :enrollments
  }

  before_create :assign_shard_id

  attr_accessible :classroom_id, :name, :user_id
  belongs_to :classroom
  belongs_to :user
  has_many :lessons

  def assign_shard_id
    self.id = School.connection.select_value( "SELECT NEXTVAL( 'shard_seq_enrollment' )")
  end
end
