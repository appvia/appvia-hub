require 'rails_helper'

RSpec.describe 'Project robot tokens end-to-end' do
  include_context 'time helpers'

  let(:quay_agent_class) { QuayAgent }
  let(:kubernetes_agent_class) { KubernetesAgent }

  let!(:user) { create :user }

  let!(:team1) { create :team }
  let!(:team2) { create :team }

  def reload_all(*args)
    user.reload
    team1.reload
    team2.reload

    args.each(&:reload)
  end

  def process_jobs
    move_time_to 1.minute.from_now
    Sidekiq::Worker.drain_all
  end

  def clear_jobs
    move_time_to 1.minute.from_now
    Sidekiq::Worker.clear_all
  end

  context 'with no integrations yet' do
    before do
      expect(quay_agent_class).to receive(:new).never
      expect(kubernetes_agent_class).to receive(:new).never
    end

    it 'doesn\'t manage any robot tokens' do
      expect(Credential.count).to eq 0

      project1, success = ProjectsService.create(
        name: 'Space 1',
        slug: 'space-1',
        team_id: team1.id
      )
      expect(success).to be true
      expect(project1.slug).to eq 'space-1'

      expect(Sidekiq::Worker.jobs.size).to eq 1

      expect_any_instance_of(quay_agent_class).to receive(:create_robot_token).never
      expect_any_instance_of(kubernetes_agent_class).to receive(:create_service_account).never

      process_jobs

      reload_all project1

      expect(Credential.count).to eq 0

      ProjectsService.destroy! project1

      expect(Sidekiq::Worker.jobs.size).to eq 1

      expect_any_instance_of(quay_agent_class).to receive(:delete_robot_token).never
      expect_any_instance_of(kubernetes_agent_class).to receive(:delete_service_account).never

      process_jobs
    end
  end

  context 'with integrations' do
    let :quay_integration_config do
      {
        'api_access_token' => 'quay API token',
        'org' => 'foo'
      }
    end

    let :kubernetes_integration_config do
      {
        'cluster_name' => 'Our Kube Cluster',
        'api_url' => 'url-to-kube-api',
        'ca_cert' => 'kube CA cert',
        'token' => 'kube API token'
      }
    end

    let :quay_agent_initializer_params do
      {
        agent_base_url: Rails.configuration.agents.quay.base_url,
        agent_token: Rails.configuration.agents.quay.token,
        quay_access_token: quay_integration_config['api_access_token'],
        org: quay_integration_config['org']
      }
    end
    let(:quay_agent) { instance_double(quay_agent_class) }

    let :kubernetes_agent_initializer_params do
      {
        agent_base_url: Rails.configuration.agents.kubernetes.base_url,
        agent_token: Rails.configuration.agents.kubernetes.token,
        kube_api_url: kubernetes_integration_config['api_url'],
        kube_ca_cert: kubernetes_integration_config['ca_cert'],
        kube_token: kubernetes_integration_config['token']
      }
    end
    let(:kubernetes_agent) { instance_double(kubernetes_agent_class) }

    before do
      expect(quay_agent_class).to receive(:new)
        .with(**quay_agent_initializer_params)
        .and_return(quay_agent)
        .at_least(:once)

      expect(kubernetes_agent_class).to receive(:new)
        .with(**kubernetes_agent_initializer_params)
        .and_return(kubernetes_agent)
        .at_least(:once)
    end

    it 'handles the management of a robot token per project per integration' do
      # Start by creating integrations, without any allocations, so open to all
      # teams.

      expect(Integration.count).to be 0

      quay_integration, quay_integration_success = Admin::IntegrationsService.create(
        name: 'Quay Integration',
        provider_id: 'quay',
        config: quay_integration_config
      )

      kubernetes_integration, kubernetes_integration_success = Admin::IntegrationsService.create(
        name: 'Kubernetes Integration',
        provider_id: 'kubernetes',
        config: kubernetes_integration_config
      )

      expect(quay_integration_success).to be true
      expect(kubernetes_integration_success).to be true
      expect(Integration.count).to be 2
      expect(quay_integration.quay?).to be true
      expect(kubernetes_integration.kubernetes?).to be true

      expect(Sidekiq::Worker.jobs.size).to eq 2

      process_jobs

      # Create a project and check that robot tokens are created accordingly.

      reload_all quay_integration, kubernetes_integration

      expect(Credential.count).to eq 0

      project1, success = ProjectsService.create(
        name: 'Space 1',
        slug: 'space-1',
        team_id: team1.id
      )
      expect(success).to be true
      expect(project1.slug).to eq 'space-1'

      expect(Sidekiq::Worker.jobs.size).to eq 1

      project1_robot_name = "hub-space-robot-#{project1.slug}"

      expect(quay_agent).to receive(:create_robot_token)
        .with(project1_robot_name, anything)
        .and_return(double(spec: double(token: 'quay_token1')))
      expect(kubernetes_agent).to receive(:create_service_account)
        .with(project1_robot_name)
        .and_return(double(spec: double(token: 'kubernetes_token1')))

      process_jobs

      reload_all quay_integration, kubernetes_integration, project1

      expect(Credential.count).to eq 2
      expect(project1.credentials.count).to eq 2
      expect(project1.credentials.pluck(:kind).uniq).to contain_exactly 'robot'
      expect(project1.credentials.pluck(:integration_id)).to contain_exactly(
        quay_integration.id,
        kubernetes_integration.id
      )
      expect(project1.credentials.pluck(:value)).to contain_exactly(
        'quay_token1',
        'kubernetes_token1'
      )

      # Create another project, but for a different team.

      project2, success = ProjectsService.create(
        name: 'Space 2',
        slug: 'space-2',
        team_id: team2.id
      )
      expect(success).to be true
      expect(project2.slug).to eq 'space-2'

      expect(Sidekiq::Worker.jobs.size).to eq 1

      project2_robot_name = "hub-space-robot-#{project2.slug}"

      expect(quay_agent).to receive(:create_robot_token)
        .with(project2_robot_name, anything)
        .and_return(double(spec: double(token: 'quay_token2')))
      expect(kubernetes_agent).to receive(:create_service_account)
        .with(project2_robot_name)
        .and_return(double(spec: double(token: 'kubernetes_token2')))

      process_jobs

      reload_all quay_integration, kubernetes_integration, project1, project2

      expect(Credential.count).to eq 4
      expect(project2.credentials.count).to eq 2
      expect(project2.credentials.pluck(:kind).uniq).to contain_exactly 'robot'
      expect(project2.credentials.pluck(:integration_id)).to contain_exactly(
        quay_integration.id,
        kubernetes_integration.id
      )
      expect(project2.credentials.pluck(:value)).to contain_exactly(
        'quay_token2',
        'kubernetes_token2'
      )

      # Now allocate the integrations to only one team and check that it updates
      # state as expected.

      quay_integration_success = Admin::IntegrationsService.update quay_integration, team_ids: [team1.id]
      kubernetes_integration_success = Admin::IntegrationsService.update kubernetes_integration, team_ids: [team1.id]

      expect(quay_integration_success).to be true
      expect(kubernetes_integration_success).to be true

      expect(quay_integration.reload.team_ids).to contain_exactly team1.id
      expect(kubernetes_integration.reload.team_ids).to contain_exactly team1.id

      expect(Sidekiq::Worker.jobs.size).to eq 2

      expect(quay_agent).to receive(:create_robot_token)
        .with(project1_robot_name, anything)
        .and_return(double(spec: double(token: nil))) # Note the `nil` token, which should be ignored
      expect(quay_agent).to receive(:delete_robot_token)
        .with(project2_robot_name)

      expect(kubernetes_agent).to receive(:create_service_account)
        .with(project1_robot_name)
        .and_return(double(spec: double(token: 'kubernetes_token1_updated')))
      expect(kubernetes_agent).to receive(:delete_service_account)
        .with(project2_robot_name)

      process_jobs

      reload_all quay_integration, kubernetes_integration, project1, project2

      expect(Credential.count).to eq 2
      expect(project1.credentials.count).to eq 2
      expect(project1.credentials.pluck(:kind).uniq).to contain_exactly 'robot'
      expect(project1.credentials.pluck(:integration_id)).to contain_exactly(
        quay_integration.id,
        kubernetes_integration.id
      )
      expect(project1.credentials.pluck(:value)).to contain_exactly(
        'quay_token1',
        'kubernetes_token1_updated'
      )
      expect(project2.credentials.count).to eq 0

      # Now make the integrations open again and check that it updates state as
      # expected.

      quay_integration_success = Admin::IntegrationsService.update quay_integration, team_ids: []
      kubernetes_integration_success = Admin::IntegrationsService.update kubernetes_integration, team_ids: []

      expect(quay_integration_success).to be true
      expect(kubernetes_integration_success).to be true

      expect(quay_integration.reload.team_ids).to be_empty
      expect(kubernetes_integration.reload.team_ids).to be_empty

      expect(Sidekiq::Worker.jobs.size).to eq 2

      expect(quay_agent).to receive(:create_robot_token)
        .with(project1_robot_name, anything)
        .and_return(double(spec: double(token: 'quay_token1')))
      expect(quay_agent).to receive(:create_robot_token)
        .with(project2_robot_name, anything)
        .and_return(double(spec: double(token: 'quay_token2')))

      expect(kubernetes_agent).to receive(:create_service_account)
        .with(project1_robot_name)
        .and_return(double(spec: double(token: nil)))
      expect(kubernetes_agent).to receive(:create_service_account)
        .with(project2_robot_name)
        .and_return(double(spec: double(token: 'kubernetes_token2_again')))

      process_jobs

      reload_all quay_integration, kubernetes_integration, project1, project2

      expect(Credential.count).to eq 4
      expect(project1.credentials.count).to eq 2
      expect(project1.credentials.pluck(:kind).uniq).to contain_exactly 'robot'
      expect(project1.credentials.pluck(:integration_id)).to contain_exactly(
        quay_integration.id,
        kubernetes_integration.id
      )
      expect(project1.credentials.pluck(:value)).to contain_exactly(
        'quay_token1',
        'kubernetes_token1_updated'
      )
      expect(project2.credentials.count).to eq 2
      expect(project2.credentials.pluck(:kind).uniq).to contain_exactly 'robot'
      expect(project2.credentials.pluck(:integration_id)).to contain_exactly(
        quay_integration.id,
        kubernetes_integration.id
      )
      expect(project2.credentials.pluck(:value)).to contain_exactly(
        'quay_token2',
        'kubernetes_token2_again'
      )

      # Now provision resources and check that the robot tokens are used.

      TeamMembershipsService.create_or_update!(
        team: team1,
        user_id: user.id,
        role: nil
      )
      TeamMembershipsService.create_or_update!(
        team: team2,
        user_id: user.id,
        role: nil
      )

      clear_jobs # We don't need to process the team membership jobs

      docker_repo = create :docker_repo,
        integration: quay_integration,
        project: project1,
        requested_by: user
      ResourceProvisioningService.new.request_create docker_repo

      kube_namespace = create :kube_namespace,
        integration: kubernetes_integration,
        project: project2,
        requested_by: user
      ResourceProvisioningService.new.request_create kube_namespace

      expect(Sidekiq::Worker.jobs.size).to eq 2

      quay_agent_create_repo_response = double(
        spec: double(
          visibility: 'private',
          url: "quay.io/#{quay_integration_config['org']}/#{docker_repo.name}"
        )
      )

      kube_agent_create_namespace_response = double

      robots = [
        {
          name: "#{quay_integration_config['org']}+#{project1_robot_name}",
          permission: 'write'
        }
      ]
      expect(quay_agent).to receive(:create_repository)
        .with(docker_repo.name, robots: robots)
        .and_return(quay_agent_create_repo_response)

      service_accounts = [
        { name: project2_robot_name }
      ]
      expect(kubernetes_agent).to receive(:create_namespace)
        .with(kube_namespace.name, service_accounts: service_accounts)
        .and_return(kube_agent_create_namespace_response)

      process_jobs

      reload_all quay_integration, kubernetes_integration, project1, project2, docker_repo, kube_namespace

      expect(docker_repo.active?).to be true
      expect(kube_namespace.active?).to be true

      # Now delete the resources.
      # Note: we don't need to test anything here as these should already be
      # covered by other tests.

      docker_repo.destroy!
      kube_namespace.destroy!

      # Now delete the projects and check that things get cleaned up as expected.

      ProjectsService.destroy! project1

      expect(Sidekiq::Worker.jobs.size).to eq 1

      expect(quay_agent).to receive(:delete_robot_token)
        .with(project1_robot_name)
        .and_return(true)
      expect(kubernetes_agent).to receive(:delete_service_account)
        .with(project1_robot_name)
        .and_return(true)

      process_jobs

      expect(Credential.count).to eq 2
      expect(project1.credentials.count).to eq 0
      expect(project2.credentials.count).to eq 2

      expect(Project.where(name: project1.name).exists?).to be false
      expect(Project.where(name: project2.name).exists?).to be true

      ProjectsService.destroy! project2

      expect(Sidekiq::Worker.jobs.size).to eq 1

      expect(quay_agent).to receive(:delete_robot_token)
        .with(project2_robot_name)
        .and_return(true)
      expect(kubernetes_agent).to receive(:delete_service_account)
        .with(project2_robot_name)
        .and_return(true)

      process_jobs

      expect(Credential.count).to eq 0

      expect(Project.where(name: project1.name).exists?).to be false
      expect(Project.where(name: project2.name).exists?).to be false
    end
  end
end
