class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :shard_to_blackboard

  def shard_to_blackboard
    RequestStore.store[:shard_name] = session[:shard_name].present? ? session[:shard_name] : nil
  end
end
