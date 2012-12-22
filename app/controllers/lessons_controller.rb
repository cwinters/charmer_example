class LessonsController < ApplicationController
  # GET /lessons
  # GET /lessons.json
  def index
    @enrollments = Enrollment.current_shard.all
    @lessons = Lesson.current_shard.all

    lesson = @lessons.first
    lesson.enrollment if lesson

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @lessons }
    end
  end

  # GET /lessons/1
  # GET /lessons/1.json
  def show
    classroom_id = params[:classroom_id]
    if classroom_id
      @lesson = Lesson.on_classroom(classroom_id).find(params[:id])
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @lesson }
      end
    else
      redirect_to lessons_url
    end
  end

  # GET /lessons/new
  # GET /lessons/new.json
  def new
    @lesson = Lesson.new()
    @classroom = Classroom.find(params[:classroom_id])
    @lesson.enrollment = @classroom.enrollments.find(params[:enrollment_id])
    @lesson.classroom_id = params[:classroom_id]
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @lesson }
    end
  end

  # GET /lessons/1/edit
  def edit
    @lesson = Lesson.find(params[:id])
  end

  # POST /lessons
  # POST /lessons.json
  def create
    respond_to do |format|
      @lesson = Lesson.shard_for_classroom(params[:lesson][:classroom_id]).create!(params[:lesson])
      if @lesson
        format.html { redirect_to @lesson, notice: 'Lesson was successfully created.' }
        format.json { render json: @lesson, status: :created, location: @lesson }
      else
        format.html { render action: "new" }
        format.json { render json: @lesson.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /lessons/1
  # PUT /lessons/1.json
  def update
    classroom_id = params[:classroom_id]
    if classroom_id
      @lesson = Lesson.shard_for_classroom(classroom_id).find(params[:id])
    else
      @lesson = nil
    end
    respond_to do |format|
      if @lesson && @lesson.update_attributes(params[:lesson])
        format.html { redirect_to @lesson, notice: 'Lesson was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @lesson.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /lessons/1
  # DELETE /lessons/1.json
  def destroy
    @lesson = Lesson.find(params[:id])
    @lesson.destroy

    respond_to do |format|
      format.html { redirect_to lessons_url }
      format.json { head :no_content }
    end
  end
end
