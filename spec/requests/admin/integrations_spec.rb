require 'rails_helper'

RSpec.describe 'Admin - Integrations', type: :request do
  include_context 'time helpers'

  describe 'index - GET /admin/integrations' do
    before do
      create_mocked_integration
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get admin_integrations_path
      end
    end

    it_behaves_like 'authenticated' do
      it_behaves_like 'not a hub admin so not allowed' do
        before do
          get admin_integrations_path
        end
      end

      it_behaves_like 'a hub admin' do
        it 'loads the admin integrations index page' do
          get admin_integrations_path
          expect(response).to be_successful
          expect(response).to render_template(:index)
          expect(assigns(:groups)).not_to be nil
        end
      end
    end
  end

  describe 'new - GET /admin/integrations/new' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get new_admin_integration_path
      end
    end

    it_behaves_like 'authenticated' do
      it_behaves_like 'not a hub admin so not allowed' do
        before do
          get new_admin_integration_path
        end
      end

      it_behaves_like 'a hub admin' do
        context 'when provider_id is invalid' do
          it 'renders an error page' do
            get new_admin_integration_path(provider_id: 'definitely_not_a_provider_id')
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end

        context 'when provider_id is valid' do
          it 'loads the new integration page' do
            get new_admin_integration_path(provider_id: 'git_hub')
            expect(response).to be_successful
            expect(response).to render_template(:new)
            expect(assigns(:integration)).to be_a Integration
            expect(assigns(:integration)).to be_new_record
            expect(assigns(:potential_parents)).not_to be nil
            expect(assigns(:potential_teams)).not_to be nil
          end
        end
      end
    end
  end

  describe 'edit - GET /admin/integrations/edit' do
    before do
      @integration = create_mocked_integration
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get edit_admin_integration_path(@integration)
      end
    end

    it_behaves_like 'authenticated' do
      it_behaves_like 'not a hub admin so not allowed' do
        before do
          get edit_admin_integration_path(@integration)
        end
      end

      it_behaves_like 'a hub admin' do
        it 'loads the edit integration page' do
          get edit_admin_integration_path(@integration)
          expect(response).to be_successful
          expect(response).to render_template(:edit)
          expect(assigns(:integration)).to eq @integration
          expect(assigns(:potential_parents)).not_to be nil
          expect(assigns(:potential_teams)).not_to be nil
        end
      end
    end
  end

  describe 'create - POST /admin/integrations' do
    let(:provider_id) { 'git_hub' }
    let(:resource_type_id) { 'CodeRepo' }

    before do
      mock_provider_config_schema provider_id
    end

    let :params do
      {
        provider_id: provider_id,
        name: 'Foo',
        config: {
          foo: 'bar'
        }
      }
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        post admin_integrations_path, params: { integration: params }
      end
    end

    it_behaves_like 'authenticated' do
      it_behaves_like 'not a hub admin so not allowed' do
        before do
          get new_admin_integration_path
        end
      end

      it_behaves_like 'a hub admin' do
        context 'with valid params' do
          it 'creates a new Integration with the given params and redirects to the integrations page' do
            expect do
              post admin_integrations_path, params: { integration: params }
              integration = assigns(:integration)
              path = admin_integrations_path(expand: resource_type_id, anchor: integration.id)
              expect(response).to redirect_to(path)
              expect(integration).to be_persisted
              expect(integration.provider_id).to eq provider_id
              expect(integration.name).to eq params[:name]
              expect(integration.config).to eq params[:config].stringify_keys
              expect(integration.created_at.to_i).to eq now.to_i
            end.to change { Integration.count }.by(1)

            expect(assigns(:potential_parents)).to be nil
            expect(assigns(:potential_teams)).to be nil
          end

          it 'logs an Audit' do
            post admin_integrations_path, params: { integration: params }
            integration = assigns(:integration)
            audit = integration.audits.order(:created_at).last
            expect(audit.action).to eq 'create'
            expect(audit.user_email).to eq auth_email
            expect(audit.created_at.to_i).to eq now.to_i
          end
        end

        context 'with invalid params' do
          it 'loads the new page with errors' do
            invalid_params = params.merge name: nil
            post admin_integrations_path, params: { integration: invalid_params }
            expect(response).to be_successful
            expect(response).to render_template(:new)
            integration = assigns(:integration)
            expect(integration).not_to be_persisted
            expect(integration.errors).to_not be_empty
            expect(integration.errors[:name]).to be_present

            expect(assigns(:potential_parents)).not_to be nil
            expect(assigns(:potential_teams)).not_to be nil
          end
        end
      end
    end
  end

  describe 'update - PUT /admin/integrations/:id' do
    let(:provider_id) { 'git_hub' }
    let(:resource_type_id) { 'CodeRepo' }

    before do
      @integration = create_mocked_integration provider_id: provider_id
    end

    let :updated_params do
      {
        name: 'Updated Name'
      }
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        put admin_integration_path(@integration), params: { integration: updated_params }
      end
    end

    it_behaves_like 'authenticated' do
      it_behaves_like 'not a hub admin so not allowed' do
        before do
          get new_admin_integration_path
        end
      end

      it_behaves_like 'a hub admin' do
        context 'with valid params' do
          it 'updates the existing Integration with the given params and redirects to the integrations page' do
            expect do
              move_time_to 1.minute.from_now
              put admin_integration_path(@integration), params: { integration: updated_params }
              integration = Integration.find @integration.id
              path = admin_integrations_path(expand: resource_type_id, anchor: integration.id)
              expect(response).to redirect_to(path)
              expect(assigns(:integration)).to eq integration
              expect(integration.name).to eq updated_params[:name]
              expect(integration.config).to eq @integration.config
              expect(integration.updated_at.to_i).to eq now.to_i
            end.to change { Integration.count }.by(0)

            expect(assigns(:potential_parents)).to be nil
            expect(assigns(:potential_teams)).to be nil
          end

          it 'logs an Audit' do
            move_time_to 1.minute.from_now
            put admin_integration_path(@integration), params: { integration: updated_params }
            integration = Integration.find @integration.id
            audit = integration.audits.order(:created_at).last
            expect(audit.action).to eq 'update'
            expect(audit.user_email).to eq auth_email
            expect(audit.created_at.to_i).to eq now.to_i
          end
        end

        context 'with invalid params' do
          it 'loads the edit page with errors' do
            put admin_integration_path(@integration), params: { integration: { name: nil } }
            expect(response).to be_successful
            expect(response).to render_template(:edit)
            integration = assigns(:integration)
            expect(integration.errors).to_not be_empty
            expect(integration.errors[:name]).to be_present

            expect(assigns(:potential_parents)).not_to be nil
            expect(assigns(:potential_teams)).not_to be nil
          end
        end

        it 'silently ignores changes to the provider_id' do
          new_provider_id = Integration.provider_ids.keys.last
          mock_provider_config_schema new_provider_id

          put admin_integration_path(@integration), params: { integration: { provider_id: new_provider_id } }
          expect(Integration.find(@integration.id).provider_id).to eq @integration.provider_id
        end
      end
    end
  end
end
