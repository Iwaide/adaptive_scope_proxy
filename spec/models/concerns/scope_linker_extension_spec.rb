require "rails_helper"

RSpec.describe ScopeLinkerExtension, type: :model do
  def log_queries(&block)
    queries = []
    counter_f = ->(_name, _started, _finished, _unique_id, payload) {
      if payload[:sql]&.include?("SELECT") && !payload[:sql]&.include?("sqlite_master")
        queries << payload[:sql]
      end
    }
    ActiveSupport::Notifications.subscribed(counter_f, "sql.active_record", &block)
    queries
  end

  before(:context) do
    class User
      has_many :linked_projects,
        class_name: "Project",
        inverse_of: :user,
        &ScopeLinkerExtension.build_has_many_extension(
          predicates: {
            active: :active?,
            with_active_labels: :with_active_labels?
          },
          filters: {
            latest_by_user: :latest_by_user_filter
          }
        )
    end
  end
  let!(:user) { create(:user) }
  let!(:active_project) { create(:project, user: user, due_on: Date.current + 1) }
  let!(:labeled_project) { create(:project, :with_active_labels, user: user, due_on: Date.current + 2) }
  let!(:latest_project) { create(:project, user: user, due_on: Date.current + 3) }
  let!(:draft_project) { create(:project, :draft, user: user) }
  let!(:archived_project) { create(:project, :archived, user: user) }

  describe "predicate extensions" do
    context "when the association is not loaded" do
      it "uses the database scope" do
        queries = log_queries do
          result = user.linked_projects.active.to_a
          expect(result).to all(satisfy(&:active?))
        end

        expect(queries.size).to be 1
        expect(queries.first).to include("archived_at")
      end
    end

    context "when the association is already loaded" do
      it "filters records without issuing another query" do
        loaded = user.linked_projects.load
        expect(loaded).to be_loaded
        queries = log_queries do
          filtered = loaded.active
          expect(filtered).to all(satisfy(&:active?))
        end

        expect(queries.size).to be 0
      end
    end
  end

  describe "filter extensions" do
    context "when the association is not loaded" do
      it "delegates to the database filter scope" do
        expected_projects = Project.latest_by_user_filter(user.projects).to_a
        queries = log_queries do
          result = user.linked_projects.latest_by_user.load
          expect(result.size).to eq 1
          expect(result).to match_array(expected_projects)
        end
        expect(queries.size).to be 1
        expect(queries.first).to include("ROW_NUMBER")
      end
    end

    context "when the association is loaded" do
      it "runs the class-level filter method instead of issuing another query" do
        allow(Project).to receive(:latest_by_user_filter).and_call_original
        expected_projects = user.projects.latest_by_user.load

        projects = user.linked_projects.load
        queries = log_queries do
          filtered = projects.load.latest_by_user
          expect(filtered.size).to eq 1
          expect(filtered).to match_array(expected_projects)
        end
        expect(Project).to have_received(:latest_by_user_filter).once
        expect(queries.size).to be 0
      end
    end
    context '複数のスコープをチェーンした場合' do
      it 'クエリがマージされて発行される' do
        queries = log_queries do
          scoped_projects = user.linked_projects.includes(:labels).active.with_active_labels
          expect(scoped_projects).to all(satisfy { |project| project.active? && project.with_active_labels? })
        end
        expect(queries.size).to be 1
        query = queries.first
        expect(query).to include('labels')
        expect(query).to include('archived_at')
      end
      context 'includesで関連モデルを事前ロードしている場合' do
        it '追加のクエリ発行がない' do
          found_user = User.includes(linked_projects: :labels).find(user.id)
          queries = log_queries do
            scoped_projects = found_user.linked_projects.active.with_active_labels
            expect(scoped_projects).to all(satisfy { |project| project.active? && project.with_active_labels? })
          end
          expect(queries.size).to be 0
        end
      end
    end
  end
end
