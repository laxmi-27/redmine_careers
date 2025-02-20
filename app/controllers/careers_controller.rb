class CareersController < ApplicationController
  before_action :find_project, only: [:index, :new, :create]
  before_action :find_career, only: [:show, :edit, :update, :destroy]

  # Show all careers for a specific project, with pagination
  def index
    @careers = @project.careers.order(created_at: :desc).paginate(page: params[:page], per_page: 10)
  end

  # Show the form to create a new career for the project
  def new
    @career = @project.careers.new
  end

  # Show a specific career for the project
  def show
  end

  # Create a new career and an associated issue for it
  def create
    @career = @project.careers.new(career_params)
  
    ActiveRecord::Base.transaction do
      # Attempt to save the career object
      unless @career.save
        flash.now[:alert] = "There was an error creating the career. Please check the form."
        render :new and return
      end
  
      # Attempt to create an issue for the newly created career
      unless create_issue_for_career(@career)
        flash[:alert] = "Career created, but issue creation failed."
        raise ActiveRecord::Rollback
      end
  
      # Handle resume upload if a resume file is provided
      if params[:career][:resume]
        resume = params[:career][:resume]
  
        if resume.is_a?(ActionDispatch::Http::UploadedFile)
          @career.resume.attach(resume)
        else
          flash[:alert] = "Invalid resume file format."
          raise ActiveRecord::Rollback
        end
      end
  
      flash[:notice] = "Career and issue created successfully!"
      redirect_to project_careers_path(@project)
    end
  end
  
  

  # Edit an existing career
  def edit
  end

  # Update an existing career
  def update
    if @career.update(career_params)
      flash[:notice] = "Career updated successfully!"
      redirect_to project_career_path(@project, @career)
    else
      flash.now[:alert] = "There was an error updating the career. Please try again."
      render :edit
    end
  end

  # Delete a career
  def destroy
    if @career.destroy
      flash[:notice] = "Career deleted successfully."
    else
      flash[:alert] = "Error deleting the career."
    end
    redirect_to project_careers_path(@project)
  end

  private

  # Find the project by ID from the URL
  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Project not found."
    redirect_to projects_path
  end

  # Find the career by ID from the URL
  def find_career
    @career = Career.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Career not found."
    redirect_to project_careers_path(@project)
  end

  # Strong parameters for career creation/update
  def career_params
    params.require(:career).permit(:name, :description, :status, :project_id, :position, :resume, :subject, :location, :experience, :qualification)
  end

  # Create an issue for the newly created career
  def create_issue_for_career(career)
    tracker = Tracker.find_by(name: 'HR')
    unless tracker
      flash[:alert] = "The 'HR' tracker does not exist. Please create it first."
      return false
    end
  
    issue = Issue.new(
      project_id: career.project_id,
      tracker_id: tracker.id,
      subject: career.name,
      description: "Location: #{career.location}\nExperience: #{career.experience}\nQualification: #{career.qualification}\nPosition: #{career.position}",
      priority_id: 2,  # Default priority (you can change it as needed)
      author_id: User.current.id,
      status_id: 1,  # Initial status (you can modify based on your flow)
      career_id: career.id
    )
  
    unless issue.save
      flash[:alert] = "Issue could not be created."
      return false
    end
  
    # Attach resume to issue if available
    if career.resume.attached?
      issue.resume.attach(career.resume.blob)
    end
  
    true
  end
  
end
