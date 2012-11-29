class User < ActiveRecord::Base
  attr_accessible :login, :name, :school_id
end
