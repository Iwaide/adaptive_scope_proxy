require "rails_helper"

RSpec.describe "Projects#index", type: :request do
  describe "GET /projects" do
    it "renders all projects whenフィルターなし" do
      project_a = create(:project, name: "Aプロジェクト")
      project_b = create(:project, name: "Bプロジェクト")

      get projects_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(project_a.name, project_b.name)
    end

    it "combines project/label/task scopes" do
      target_project = create(:project, name: "一致プロジェクト", status: "active", risk_level: "medium")
      other_project = create(:project, name: "別プロジェクト", status: "draft", risk_level: "low")

      label = create(:label, :risk_flag, :billable_only, project: target_project, archived_at: nil)
      create(:task, :billable, :overdue, project: target_project, label: label)
      create(:task, :billable, :slipping, project: target_project, label: label)

      create(:label, project: other_project)
      create(:task, project: other_project)

      get projects_path,
          params: {
            active: 1,
            needs_attention: 1,
            label_risk: 1,
            billable_labels: 1,
            billable_tasks: 1,
            slipping_tasks: 1
          }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(target_project.name)
      expect(response.body).not_to include(other_project.name)
    end

    it "returns healthy projects when requested" do
      healthy_project = create(:project, :low_risk, name: "ヘルシー", status: "active")
      create(:task, project: healthy_project, label: create(:label, project: healthy_project), estimate_minutes: 120, worked_minutes: 60)

      risky_project = create(:project, name: "リスキー", status: "active", risk_level: "high")
      create(:task, :slipping, project: risky_project, label: create(:label, project: risky_project))

      get projects_path, params: { healthy: 1 }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(healthy_project.name)
      expect(response.body).not_to include(risky_project.name)
    end
  end
end
