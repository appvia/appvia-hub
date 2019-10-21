require 'rails_helper'

RSpec.describe 'bin/rails hub:danger_zone:clean_hub', type: :task do
  subject do
    Rake::Task['hub:danger_zone:clean_hub']
  end

  before do
    @initial_audit_count = Audit.count

    @integration1 = create_mocked_integration provider_id: 'git_hub'
    @integration2 = create_mocked_integration provider_id: 'git_hub'

    @user = create :user

    @team1 = create :team
    @team2 = create :team

    @team1_membership = create :team_membership, team: @team1, user: @user
    @team2_membership = create :team_membership, team: @team2, user: @user

    create :allocation, allocatable: @integration2, allocation_receivable: @team2

    @team1_project1 = create :project, team: @team1
    @team1_project2 = create :project, team: @team1
    @team2_project1 = create :project, team: @team2

    @team1_project1_resource1 = create :code_repo,
      integration: @integration1,
      project: @team1_project1,
      requested_by: @user,
      full_name: 'foo/resource1'
    @team2_project1_resource1 = create :code_repo,
      integration: @integration2,
      project: @team2_project1,
      requested_by: @user,
      full_name: 'foo/resource2s'

    @unaffected_audits_count = 3 # The ones for user(s) + integration(s)
    @full_audit_count = @initial_audit_count + 13

    # Pre checks
    expect(Team.count).to eq 2
    expect(TeamMembership.count).to eq 2
    expect(Allocation.count).to eq 1
    expect(Project.count).to eq 3
    expect(Resource.count).to eq 2
    expect(@team1.audits.count).to eq 1
    expect(@team1.associated_audits.count).to eq 3
    expect(@team2.audits.count).to eq 1
    expect(@team2.associated_audits.count).to eq 3
    expect(@team1_project1.audits.count).to eq 1
    expect(@team1_project1.associated_audits.count).to eq 1
    expect(@team1_project2.audits.count).to eq 1
    expect(@team1_project2.associated_audits.count).to eq 0
    expect(@team2_project1.audits.count).to eq 1
    expect(@team2_project1.associated_audits.count).to eq 1
    expect(Audit.count).to eq @full_audit_count

    # Mock out agent(s)
    @agent = instance_double('GitHubAgent')
    allow(GitHubAgent).to receive(:new)
      .with(anything)
      .and_return(@agent)
  end

  it 'preloads the Rails environment' do
    expect(subject.prerequisites).to include 'environment'
  end

  context 'with no exclusions' do
    it 'cleans up all resources, projects and teams, along with their relevant audits' do
      expect(@agent).to receive(:delete_repository)
        .with(@team1_project1_resource1.full_name)
        .and_return(true)
      expect(@agent).to receive(:delete_repository)
        .with(@team2_project1_resource1.full_name)
        .and_return(true)
      expect(@agent).to receive(:delete_team)
        .with(SyncIntegrationTeamService.build_team_name(@team1.slug))
        .and_return(true)
      expect(@agent).to receive(:delete_team)
        .with(SyncIntegrationTeamService.build_team_name(@team2.slug))
        .and_return(true)
        .twice

      subject.execute

      expect(Team.count).to eq 0
      expect(TeamMembership.count).to eq 0
      expect(Allocation.count).to eq 0
      expect(Project.count).to eq 0
      expect(Resource.count).to eq 0
      expect(Audit.count).to eq(@initial_audit_count + @unaffected_audits_count)
    end
  end

  context 'with some exclusions' do
    context 'with project exclusion only' do
      before do
        ENV['EXCLUDE_SPACES'] = [
          @team1_project1.slug,
          @team1_project2.slug
        ].join(',')
      end

      after do
        ENV.delete 'EXCLUDE_SPACES'
      end

      it 'cleans up just the resources, projects and teams that it should, along with their relevant audits' do
        expect(@agent).to receive(:delete_repository)
          .with(@team1_project1_resource1.full_name)
          .never
        expect(@agent).to receive(:delete_repository)
          .with(@team2_project1_resource1.full_name)
          .and_return(true)
        expect(@agent).to receive(:delete_team)
          .with(SyncIntegrationTeamService.build_team_name(@team1.slug))
          .never
        expect(@agent).to receive(:delete_team)
          .with(SyncIntegrationTeamService.build_team_name(@team2.slug))
          .and_return(true)
          .twice

        subject.execute

        expect(Team.count).to eq 1
        expect(TeamMembership.count).to eq 1
        expect(Allocation.count).to eq 0
        expect(Project.count).to eq 2
        expect(Project.pluck(:slug)).to contain_exactly(
          @team1_project1.slug,
          @team1_project2.slug
        )
        expect(Resource.count).to eq 1
        expect(Audit.count).to eq(@full_audit_count - 5)
      end
    end

    context 'with team exclusion only' do
      before do
        ENV['EXCLUDE_TEAMS'] = @team2.slug
      end

      after do
        ENV.delete 'EXCLUDE_TEAMS'
      end

      it 'cleans up just the resources, projects and teams that it should, along with their relevant audits' do
        expect(@agent).to receive(:delete_repository)
          .with(@team1_project1_resource1.full_name)
          .and_return(true)
        expect(@agent).to receive(:delete_repository)
          .with(@team2_project1_resource1.full_name)
          .never
        expect(@agent).to receive(:delete_team)
          .with(SyncIntegrationTeamService.build_team_name(@team1.slug))
          .and_return(true)
        expect(@agent).to receive(:delete_team)
          .with(SyncIntegrationTeamService.build_team_name(@team2.slug))
          .never

        subject.execute

        expect(Team.count).to eq 1
        expect(TeamMembership.count).to eq 1
        expect(Allocation.count).to eq 1
        expect(Project.count).to eq 1
        expect(Project.pluck(:slug)).to contain_exactly @team2_project1.slug
        expect(Resource.count).to eq 1
        expect(Audit.count).to eq(@full_audit_count - 5)
      end
    end

    context 'with both project and team exclusions' do
      before do
        ENV['EXCLUDE_SPACES'] = @team1_project2.slug
        ENV['EXCLUDE_TEAMS'] = @team2.slug
      end

      after do
        ENV.delete 'EXCLUDE_SPACES'
        ENV.delete 'EXCLUDE_TEAMS'
      end

      it 'cleans up just the resources, projects and teams that it should, along with their relevant audits' do
        expect(@agent).to receive(:delete_repository)
          .with(@team1_project1_resource1.full_name)
          .and_return(true)
        expect(@agent).to receive(:delete_repository)
          .with(@team2_project1_resource1.full_name)
          .never
        expect(@agent).to receive(:delete_team)
          .with(SyncIntegrationTeamService.build_team_name(@team1.slug))
          .never
        expect(@agent).to receive(:delete_team)
          .with(SyncIntegrationTeamService.build_team_name(@team2.slug))
          .never

        subject.execute

        expect(Team.count).to eq 2
        expect(TeamMembership.count).to eq 2
        expect(Allocation.count).to eq 1
        expect(Project.count).to eq 2
        expect(Project.pluck(:slug)).to contain_exactly(
          @team1_project2.slug,
          @team2_project1.slug
        )
        expect(Resource.count).to eq 1
        expect(Audit.count).to eq(@full_audit_count - 2)
      end
    end
  end
end
