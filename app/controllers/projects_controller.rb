class ProjectsController < ApplicationController
  def index
    sqls = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, payload|
      next if payload[:name] == "SCHEMA"
      next if payload[:sql].match?(/\A(?:BEGIN|COMMIT|ROLLBACK)\b/i)

      sqls << payload[:sql]
    end
    @projects = Project.valid_latest_projects_for
    @executed_sql = sqls
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end
end
