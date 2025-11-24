

require "rails_helper"

RSpec.describe ScopeLinker, type: :model do
  def log_project_loads(&block)
    queries = []
    counter_f = ->(_name, _started, _finished, _unique_id, payload) {
      if payload[:name] == "Project Load"
        queries << payload[:sql]
      end
    }
    ActiveSupport::Notifications.subscribed(counter_f, "sql.active_record", &block)
    queries
  end

  before do
    Project.include described_class unless Project < described_class
  end
  before do
    create(:project)
    create(:project, :draft)
  end

  describe ".link_scope_predicate" do
    context 'scopeが存在しない場合' do
      it 'ArgumentErrorを発生させる' do
        expect {
          Project.link_scope_predicate(:non_existent_scope)
        }.to raise_error(ArgumentError, /Scope non_existent_scope is not defined/)
      end
    end
    context 'predicateメソッドが存在しない場合' do
      it 'ArgumentErrorを発生させる' do
        expect {
          Project.link_scope_predicate(:active, predicate: :non_existent_predicate?)
        }.to raise_error(ArgumentError, /Predicate method non_existent_predicate\? is not defined/)
      end
    end
    context 'scopeとpredicateメソッドが両方存在する場合' do
      it 'link_scope_predicateの設定ができる' do
        expect {
          Project.link_scope_predicate(:active)
        }.not_to raise_error
      end

      context 'レコードがロードされていない場合' do
        it 'DBクエリを使用してスコープを適用する' do
          Project.link_scope_predicate(:active)
          expect(Project).to receive(:active)
          Project.linked_active
        end
      end
      context 'レコードがロードされている場合' do
        it 'Rubyのフィルタリングを使用してスコープを適用する' do
          queries = log_project_loads do
            projects = Project.all.load
            active_projects = projects.linked_active
            expect(active_projects).to all(satisfy { |project| project.active? })
          end
          expect(queries.size).to be 1
        end

        it 'scopeを直接使用するとDBクエリが発行される' do
          queries = log_project_loads do
            projects = Project.all.load
            active_projects = projects.active
            expect(active_projects).to all(satisfy { |project| project.active? })
          end
          expect(queries.size).to be 2
        end
      end

      context '複数回link_scope_predicateを呼び出した場合' do
        context 'includesで関連モデルを事前ロードしている場合' do
          it '1回のクエリ発行で済む' do
            expect {
              Project.link_scope_predicate(:active)
              Project.link_scope_predicate(:with_active_labels)
            }.not_to raise_error

            queries = log_project_loads do
              projects = Project.all.includes(:labels).load
              scoped_projects = projects.linked_active.linked_with_active_labels
              expect(scoped_projects).to all(satisfy { |project| project.active? && project.with_active_labels? })
            end
            expect(queries.size).to be 1
          end
        end

        context 'includesで関連モデルを事前ロードしていない場合' do
          it '各スコープごとにクエリが発行される' do
            expect {
              Project.link_scope_predicate(:active)
              Project.link_scope_predicate(:with_active_labels)
            }.not_to raise_error

            queries = log_project_loads do
              projects = Project.all.load
              scoped_projects = projects.linked_active.linked_with_active_labels
              expect(scoped_projects).to all(satisfy { |project| project.active? && project.with_active_labels? })
            end
            expect(queries.size).to be 2
          end
        end
      end
    end
  end

  describe '.link_scope_filter' do
    context 'scopeが存在しない場合' do
      it 'ArgumentErrorを発生させる' do
        expect {
          Project.link_scope_filter(:non_existent_scope)
        }.to raise_error(ArgumentError, /Scope non_existent_scope is not defined/)
      end
    end
    context 'filterメソッドが存在しない場合' do
      it 'ArgumentErrorを発生させる' do
        expect {
          Project.link_scope_filter(:active, filter: :non_existent_filter)
        }.to raise_error(ArgumentError, /Filter method non_existent_filter is not defined/)
      end
    end
    context 'scopeとfilterメソッドが両方存在する場合' do
      it 'link_scope_filterの設定ができる' do
        expect {
          Project.link_scope_filter(:latest_by_user, filter: :latest_by_user_filter)
        }.not_to raise_error
      end

      context 'レコードがロードされていない場合' do
        it 'DBクエリを使用してスコープを適用する' do
          queries = log_project_loads do
            Project.link_scope_filter(:latest_by_user, filter: :latest_by_user_filter)
            expect(Project).to receive(:latest_by_user).and_call_original
            Project.linked_latest_by_user.load
          end
          expect(queries.size).to be 1
          expect(queries.first).to include("ROW_NUMBER")
        end
      end
      context 'レコードがロードされている場合' do
        it 'Rubyのフィルタリングを使用してスコープを適用する' do
          queries = log_project_loads do
            projects = Project.all.load
            latest_projects = projects.linked_latest_by_user
            user_ids = latest_projects.map(&:user_id)
            expect(user_ids.size).to eq user_ids.uniq.size
          end
          expect(queries.size).to be 1
          expect(queries.first).not_to include("ROW_NUMBER")
        end
      end
    end
  end
end
