class ProjectsController < ApplicationController
  def index
    projects = Project.all

    projects = projects.active if params[:active].present?
    projects = projects.needs_attention if params[:needs_attention].present?
    projects = projects.healthy if params[:healthy].present?

    projects = projects.with_active_labels if params[:active_labels].present?
    projects = projects.with_risk_flag_labels if params[:label_risk].present?
    projects = projects.with_billable_labels if params[:billable_labels].present?

    projects = projects.with_billable_tasks if params[:billable_tasks].present?
    projects = projects.with_overdue_tasks if params[:overdue_tasks].present?
    projects = projects.with_slipping_tasks if params[:slipping_tasks].present?

    projects = projects.includes(:labels, :tasks)
    @projects = projects.distinct
  end
end
