class User < ActiveRecord::Base
  attr_accessible :login, :name, :school_id
  belongs_to :school
  #has_many :attempts
  #has_many :enrollments

  def enrollments
    []
  end
end
