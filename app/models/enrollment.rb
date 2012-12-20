class Enrollment < ActiveRecord::Base
  include ShardedModel

  db_magic :sharded => {
      key: :classroom_id, sharded_connection: :enrollments
  }

  before_create :assign_shard_id

  attr_accessible :classroom_id, :name, :user_id

  belongs_to :classroom
  belongs_to :user
  has_many :lessons

  def lessons
    super.on_db(shard_name(self.classroom_id))
  end

  # eep! try all shards to find an object
  def self.multi_find(id)
    enum       = CharmerExample::Application.config.shards.to_enum
    enrollment = nil
    loop do
      begin
        enrollment = Enrollment.on_db(enum.next).find(id)
        break if enrollment
      rescue
        # ignored
      end
    end
    return enrollment
  end

  def full_name
    "#{user.login} in #{classroom.name}: #{name}"
  end

  private
  def assign_shard_id
    self.id = School.connection.select_value("SELECT NEXTVAL( 'shard_seq_enrollment' )")
  end
end
