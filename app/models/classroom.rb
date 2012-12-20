class Classroom < ActiveRecord::Base
  attr_accessible :name, :school_id
  belongs_to :school
  has_many :enrollments

  def enrollments
    conn = Enrollment.sharded_connection.sharder.shard_for_key(self.id.to_s)
    super.on_db(conn, nil)
  end

  def full_name
    "#{school.name}: #{name}"
  end
end
