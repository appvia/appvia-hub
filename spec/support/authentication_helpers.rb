module AuthenticationHelpers
  RSpec.shared_context 'authentication helpers' do
    let(:auth_subject) { '123456' }
    let(:auth_email) { 'foo@example.com' }
    let(:auth_name) { 'Ms Foo' }

    let :auth_headers do
      {
        'X-Auth-Subject' => auth_subject,
        'X-Auth-Email' => auth_email,
        'X-Auth-Username' => auth_name
      }.compact
    end

    def current_user
      User.find_or_create_by!(email: auth_email) do |u|
        u.name = auth_name
      end
    end
  end

  RSpec.shared_examples 'unauthenticated not allowed' do
    it 'returns a 401 Unauthorized' do
      expect(response).to have_http_status(401)
    end
  end

  RSpec.shared_examples 'authenticated' do
    include RequestHelpersAuthOverrides

    before do
      # Reset the current_user's role in case they were made a hub admin automatically
      current_user.update! role: User.roles[:user]
    end
  end

  module RequestHelpersAuthOverrides
    # Override the ActionDispatch::Integration::RequestHelpers with our own, so
    # we can inject the headers required for authentication.
    %w[get post patch put delete head].each do |m|
      define_method m do |path, **args|
        super path, **_args_with_auth_headers(args)
      end
    end

    def _args_with_auth_headers(args)
      args[:headers] = Hash(args[:headers]).merge auth_headers
      args
    end
  end
end
