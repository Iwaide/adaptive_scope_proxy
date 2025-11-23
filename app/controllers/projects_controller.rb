class ProjectsController < ApplicationController
  def index
    projects = Project.all

    projects = projects.includes(:labels, :tasks)
    projects = projects.active.with_risk_flag_labels.with_slipping_tasks

    sqls = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, payload|
      next if payload[:name] == "SCHEMA"
      next if payload[:sql].match?(/\A(?:BEGIN|COMMIT|ROLLBACK)\b/i)

      sqls << payload[:sql]
    end

    @projects = projects.distinct.load
    @executed_sql = sqls
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end
end
