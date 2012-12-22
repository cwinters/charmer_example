class ShardsController < ApplicationController
  def assign
    shard_name = params[:shard_name]
    if shard_name
      session[:shard_name] = shard_name
    else
      session.delete(:shard_name)
    end
    next_url = request.referrer || '/classrooms'
    redirect_to next_url
  end
end