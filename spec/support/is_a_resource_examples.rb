module IsAResourceExamples
  RSpec.shared_examples 'is a Resource' do
    describe 'is a Resource' do
      let(:factory) { described_class.model_name.element.to_sym }

      let(:integration) { create_mocked_integration }

      subject { create factory, integration: integration }

      describe '#project' do
        it { is_expected.to belong_to(:project) }
        it { is_expected.to have_readonly_attribute(:project_id) }
      end

      describe '#integration' do
        it { is_expected.to belong_to(:integration).class_name('Integration') }
        it { is_expected.to have_readonly_attribute(:integration_id) }
      end

      describe '#requested_by' do
        it { is_expected.to belong_to(:requested_by).class_name('User') }
        it { is_expected.to have_readonly_attribute(:requested_by_id) }
      end

      describe '#status' do
        it { is_expected.to define_enum_for(:status).backed_by_column_of_type(:string) }
        it { is_expected.to validate_presence_of(:status) }

        it 'has a default value' do
          expect(described_class.new.status).to eq 'pending'
        end
      end

      describe '#name' do
        include_examples 'slugged_attribute',
          :name,
          presence: true,
          uniqueness: { scope: :integration_id },
          readonly: true

        describe 'uniqueness check' do
          let(:project) { create :project, name: 'project-1' }
          let(:other_project) { create :project, name: 'project-2' }

          let(:other_integration) { create_mocked_integration }

          let(:name) { 'foo' }
          let(:other_name) { 'bar' }

          before do
            create(
              factory,
              name: name,
              project: project,
              integration: integration
            )
          end

          it 'does not allow the same name for resources, for the same integration, in the same project' do
            other_resource = build(
              factory,
              name: name,
              project: project,
              integration: integration
            )

            expect(other_resource).not_to be_valid
            expect(other_resource.errors[:name].first).to eq 'has already been taken'
          end

          it 'does not allow the same name for resources, for the same integration, in different projects' do
            other_resource = build(
              factory,
              name: name,
              project: other_project,
              integration: integration
            )

            expect(other_resource).not_to be_valid
            expect(other_resource.errors[:name].first).to eq 'has already been taken'
          end

          it 'allows different names for resources, for the same integration, in the same project' do
            other_resource = build(
              factory,
              name: other_name,
              project: project,
              integration: integration
            )

            expect(other_resource).to be_valid
          end

          it 'allows the same name for resources, for different integrations, in the same project' do
            other_resource = build(
              factory,
              name: name,
              project: project,
              integration: other_integration
            )

            expect(other_resource).to be_valid
          end
        end
      end
    end
  end
end
