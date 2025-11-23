class ProjectsController < ApplicationController
  def index
    projects = Project.all

    projects = projects.active if params[:active].present?
    projects = projects.needs_attention if params[:needs_attention].present?
    projects = projects.healthy if params[:healthy].present?

    label_scopes = []
    label_scopes << Label.active if params[:active_labels].present?
    label_scopes << Label.risk_flags if params[:label_risk].present?
    label_scopes << Label.applied_to_billable_tasks if params[:billable_labels].present?
    if label_scopes.any?
      projects = projects.joins(:labels)
      label_scopes.each do |label_scope|
        projects = projects.merge(label_scope)
      end
    end

    task_scopes = []
    task_scopes << Task.billable if params[:billable_tasks].present?
    task_scopes << Task.overdue if params[:overdue_tasks].present?
    task_scopes << Task.slipping if params[:slipping_tasks].present?
    if task_scopes.any?
      projects = projects.joins(:tasks)
      task_scopes.each do |task_scope|
        projects = projects.merge(task_scope)
      end
    end

    @projects = projects.distinct
  end
end
