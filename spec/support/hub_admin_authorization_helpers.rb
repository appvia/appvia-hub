module HubAdminAuthorizationHelpers
  # The helpers here need to be used within the shared examples defined in
  # authentication_helpers, otherwise they won't work.

  RSpec.shared_examples 'not a hub admin so not allowed' do
    before do
      current_user.update! role: User.roles[:user]
    end

    it 'redirects to the root page' do
      expect(response).to redirect_to root_path
      expect(flash[:alert]).not_to be_empty
    end
  end

  RSpec.shared_examples 'a hub admin' do
    before do
      current_user.admin!
    end
  end
end
