class Attempt < ActiveRecord::Base
  attr_accessible :correct, :lesson_id, :response, :user_id
  belongs_to :lesson
  belongs_to :user
end
