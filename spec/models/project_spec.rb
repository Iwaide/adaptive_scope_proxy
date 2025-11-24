require "rails_helper"

RSpec.describe Project do
  describe ".latest_by_user" do
    it "returns the latest project per user ordered by due date" do
      user_a = create(:user)
      user_b = create(:user)

      older = create(:project, user: user_a, due_on: Date.new(2024, 1, 1))
      latest = create(:project, user: user_a, due_on: Date.new(2024, 2, 1))
      other_user_project = create(:project, user: user_b, due_on: Date.new(2024, 3, 1))

      result = described_class.latest_by_user

      expect(result).to contain_exactly(latest, other_user_project)
      expect(result).not_to include(older)
    end
  end
end
