class EnrollmentsController < ApplicationController
  # GET /enrollments
  # GET /enrollments.json

  before_filter :check_shard

  def index
    @enrollments = Enrollment.on_db(session[:shard_name]).all
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @enrollments }
    end
  end

  # GET /enrollments/1
  # GET /enrollments/1.json
  def show
    @enrollment = Enrollment.on_db(session[:shard_name]).find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @enrollment }
    end
  end

  # GET /enrollments/new
  # GET /enrollments/new.json
  def new
    @enrollment = Enrollment.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @enrollment }
    end
  end

  # GET /enrollments/1/edit?classroom_id=5
  def edit
    @enrollment = Enrollment.shard_for( params[:classroom_id] ).find(params[:id])
  end

  # POST /enrollments
  # POST /enrollments.json
  def create
    #@enrollment = Enrollment.new(params[:enrollment])

    respond_to do |format|
      @enrollment = Enrollment.shard_for( params[:enrollment][:classroom_id] ).create!( params[:enrollment] )
      if @enrollment
        format.html { redirect_to @enrollment, notice: 'Enrollment was successfully created.' }
        format.json { render json: @enrollment, status: :created, location: @enrollment }
      else
        format.html { render action: "new" }
        format.json { render json: @enrollment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /enrollments/1
  # PUT /enrollments/1.json
  def update

    @enrollment = Enrollment.shard_for( params[:enrollment][:classroom_id] ).find(params[:id])

    respond_to do |format|
      if @enrollment.update_attributes(params[:enrollment])
        format.html { redirect_to @enrollment, notice: 'Enrollment was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @enrollment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /enrollments/1
  # DELETE /enrollments/1.json
  def destroy
    @enrollment = Enrollment.shard_for( params[:classroom_id] ).find(params[:id])
    @enrollment.destroy

    respond_to do |format|
      format.html { redirect_to enrollments_url }
      format.json { head :no_content }
    end
  end

  def check_shard
    unless session[:shard_name].present?
      flash[:notice] = "Choose a shard before manipulating enrollments."
      redirect_to '/classrooms'
    end
    session[:shard_name].present?
  end
end
