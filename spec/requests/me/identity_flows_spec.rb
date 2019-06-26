require 'rails_helper'

RSpec.describe 'Me - Identity Flows', type: :request do
  include_context 'time helpers'

  describe 'GitHub identity flows' do
    let :git_hub_identity_service do
      instance_double 'GitHubIdentityService'
    end

    before do
      allow(GitHubIdentityService).to receive(:new)
        .and_return(git_hub_identity_service)
    end

    describe 'git_hub_start - GET /me/identity_flows/:integration_id/git_hub/start' do
      let :integration do
        create_mocked_integration
      end

      it_behaves_like 'unauthenticated not allowed' do
        before do
          get me_identity_flow_git_hub_start_path(integration_id: integration.id)
        end
      end

      it_behaves_like 'authenticated' do
        let :base_url do
          'http://localhost'
        end

        let :callback_url do
          URI.join(
            base_url,
            "/me/identity_flows/#{integration.id}/git_hub/callback"
          ).to_s
        end

        before do
          allow(Rails.configuration).to receive(:base_url)
            .and_return(base_url)
        end

        it 'redirects to the GitHub OAuth authorize endpoint with an appropriate callback_url' do
          git_hub_auth_url = 'git_hub_auth_url'
          expect(git_hub_identity_service).to receive(:authorize_url)
            .with(current_user, callback_url)
            .and_return(git_hub_auth_url)

          get me_identity_flow_git_hub_start_path(integration_id: integration.id)

          expect(response).to redirect_to(git_hub_auth_url)
        end
      end
    end

    describe 'git_hub_callback - GET /me/identity_flows/:integration_id/git_hub/callback' do
      let :integration do
        create_mocked_integration
      end

      # Note: not an authenticated endpoint

      it 'handles a missing "code" param' do
        expect(git_hub_identity_service).to receive(:connect_identity).never

        get me_identity_flow_git_hub_callback_path(integration_id: integration.id, state: 'foo')

        expect(response).to redirect_to(root_path)
      end

      it 'handles a missing "state" param' do
        expect(git_hub_identity_service).to receive(:connect_identity).never

        get me_identity_flow_git_hub_callback_path(integration_id: integration.id, code: 'foo')

        expect(response).to redirect_to(root_path)
      end

      context 'with an invalid integration' do
        let :invalid_integration do
          create_mocked_integration provider_id: 'kubernetes'
        end

        it 'renders an error page' do
          expect(git_hub_identity_service).to receive(:connect_identity).never

          get me_identity_flow_git_hub_callback_path(integration_id: invalid_integration.id, code: 'foo', state: 'bar')

          expect(response).to have_http_status(422)
        end
      end

      context 'the GitHubIdentityService throws a NoAccessToken error' do
        let(:code) { 'code' }
        let(:state) { 'state' }

        before do
          expect(git_hub_identity_service).to receive(:connect_identity)
            .with(integration, code, state)
            .and_raise(GitHubIdentityService::NoAccessToken)
        end

        it 'handles the error and responds with an HTTP 403' do
          get me_identity_flow_git_hub_callback_path(integration_id: integration.id, code: code, state: state)
          expect(response).to have_http_status(403)
        end
      end
    end
  end
end
