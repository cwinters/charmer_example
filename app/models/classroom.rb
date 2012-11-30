class Classroom < ActiveRecord::Base
  attr_accessible :name, :school_id
  belongs_to :school
  has_many :enrollments

  def full_name
    "#{school.name}: #{name}"
  end
end
