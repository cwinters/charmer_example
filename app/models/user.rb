class User < ActiveRecord::Base
  attr_accessible :login, :name, :school_id
  belongs_to :school
end
