require 'rails_helper'

RSpec.describe 'Me - Identities', type: :request do
  include_context 'time helpers'

  describe 'destroy - DELETE /me/identities/:integration_id' do
    let :integration do
      create_mocked_integration
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        delete me_identity_path(integration_id: integration.id)
      end
    end

    it_behaves_like 'authenticated' do
      let!(:other_user) { create :user }
      let! :other_identity do
        create :identity, user: other_user, integration: integration
      end

      context 'for an integration that doesn\'t exist' do
        it 'throws an error' do
          expect do
            delete me_identity_path(integration_id: 'does-not-exist')
          end.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when the user doesn\'t have an identity for the integration' do
        it 'throws an error' do
          original_identity_count = Identity.count

          expect do
            delete me_identity_path(integration_id: integration.id)
          end.to raise_error(ActiveRecord::RecordNotFound)

          expect(Identity.count).to eq original_identity_count
        end
      end

      context 'when the user does have an identity for the integration' do
        let! :identity do
          create :identity, user: current_user, integration: integration
        end

        it 'deletes the user\'s identity for the specified integration' do
          expect do
            delete me_identity_path(integration_id: integration.id)
          end.to change(Identity, :count).by(-1)

          expect(response).to redirect_to(me_access_path)

          expect(Identity.exists?(id: identity.id)).to be false
          expect(Identity.exists?(id: other_identity.id)).to be true
        end
      end
    end
  end
end
