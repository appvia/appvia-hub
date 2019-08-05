require 'rails_helper'

RSpec.describe Team, type: :model do
  subject { create :team }

  describe '#name' do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe '#slug' do
    include_examples 'slugged_attribute',
      :slug,
      presence: true,
      uniqueness: true,
      readonly: true
  end
end
