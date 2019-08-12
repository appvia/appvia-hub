require 'rails_helper'

RSpec.describe User, type: :model do
  it 'normalises the email before validating' do
    user = create :user, email: 'Foo@BAR.coM'
    expect(user.valid?).to be true
    expect(user.email).to eq 'foo@bar.com'
  end

  describe '#search' do
    let!(:user_1) { create :user, name: 'Bobina', email: 'bb@lolz.com' }
    let!(:user_2) { create :user, name: nil, email: 'bobsmith@gooogle.com' }
    let!(:user_3) { create :user, name: 'Foo Bar Baz', email: 'foo1@lolz.com' }

    before do
      # Create some other users to ensure we have a pool of users to pick from
      create_list :user, 3
    end

    it 'works as expected' do
      expect(User.search('Bobina')).to contain_exactly user_1
      expect(User.search('bb')).to contain_exactly user_1
      expect(User.search('bob')).to contain_exactly user_1, user_2
      expect(User.search('bobsmith')).to contain_exactly user_2
      expect(User.search('lolz.com')).to contain_exactly user_1, user_3
      expect(User.search('baz')).to contain_exactly user_3
      expect(User.search('Foo')).to contain_exactly user_3
      expect(User.search('Foo Bar')).to contain_exactly user_3
      expect(User.search('Bar Baz')).to contain_exactly user_3
    end
  end
end
