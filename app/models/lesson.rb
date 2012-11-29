class Lesson < ActiveRecord::Base
  attr_accessible :enrollment_id, :name
  belongs_to :enrollment
  has_many :attempts
end
