class User < ActiveRecord::Base
  attr_accessible :login, :name, :school_id
  belongs_to :school
  #has_many :attempts -- how will these work?
  #has_many :enrollments -- how will these work?

  # this needs to use the cache key
  def enrollments
    []
  end

  def attempts
    []
  end

end
