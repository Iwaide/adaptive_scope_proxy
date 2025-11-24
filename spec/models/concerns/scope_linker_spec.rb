

require "rails_helper"

RSpec.describe ScopeLinker, type: :model do
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
          projects = Project.all.load
          expect(projects).not_to receive(:active)
          active_projects = projects.linked_active
          expect(active_projects).to all(satisfy { |project| project.active? })
        end
        it 'scopeを直接使用するとDBクエリが発行される' do
          projects = Project.all.load
          active_projects = projects.active
          expect(active_projects).to all(satisfy { |project| project.active? })
        end
      end
    end
  end
end
