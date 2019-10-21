# rubocop:disable Metrics/BlockLength
namespace :hub do
  namespace :danger_zone do
    desc [
      'WARNING: will delete all resources, spaces and teams,',
      'together with their audit entries. Note (1): will still delete resources',
      'in the db even if agent(s) throw an error for request deletes. ',
      'Note (2): you can exclude certain spaces, and/or teams, by setting th`EXCLUDE_SPACES`, and/or `EXCLUDE_TEAMS`, env vars ',
      '(using the slugs for spaces and teams as the identifier), ',
      'e.g.: EXCLUDE_SPACES="foo-1,bar,another-space" EXCLUDE_TEAMS="team-x" bin/rails hub:danger_zone:clean_hub'
    ].join(' ')
    task clean_hub: :environment do
      exclude_spaces = Array(
        (ENV['EXCLUDE_SPACES'] || '').split(',')
      ).map(&:strip)
      exclude_teams = Array(
        (ENV['EXCLUDE_TEAMS'] || '').split(',')
      ).map(&:strip)

      exclude_project_ids = if exclude_spaces.present?
                              Project.where(slug: exclude_spaces).pluck(:id)
                            else
                              []
                            end
      exclude_team_ids = if exclude_teams.present?
                           Team.where(slug: exclude_teams).pluck(:id)
                         else
                           []
                         end

      require 'sidekiq/testing'
      Sidekiq::Testing.inline! do
        HubCleaner.delete_resources exclude_project_ids, exclude_team_ids
        HubCleaner.delete_projects exclude_project_ids, exclude_team_ids
        HubCleaner.delete_teams exclude_team_ids
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength

module HubCleaner
  class << self
    def delete_resources(exclude_project_ids, exclude_team_ids)
      provisioning_service = ResourceProvisioningService.new

      ids = []

      Resource.where.not(project_id: exclude_project_ids).each do |r|
        next if exclude_team_ids.include?(r.project.team_id)

        ids << r.id
        Rails.logger.info "Requesting deletion for resource '#{r.descriptor}' (ID: #{r.id})"
        provisioning_service.request_delete r
      rescue ActiveRecord::StaleObjectError
        # Handle optimistic locking error
        r.reload.destroy! if Resource.exists? r.id
      end

      # Just in case they've hung around due to errors from the agent.
      Resource.where.not(project_id: exclude_project_ids).each do |r|
        next if exclude_team_ids.include?(r.project.team_id)

        r.destroy!
      end

      delete_audits_for 'Resource', ids
    end

    def delete_projects(exclude_project_ids, exclude_team_ids)
      ids = []

      Project.where.not(id: exclude_project_ids).each do |p|
        next if exclude_team_ids.include?(p.team_id)

        ids << p.id
        Rails.logger.info "Requesting deletion for space '#{p.slug}' (ID: #{p.id})"
        ProjectsService.destroy!(p)
      end

      delete_audits_for 'Project', ids
      delete_associated_audits_for 'Project', ids
    end

    def delete_teams(exclude_team_ids)
      ids = []

      Team.where.not(id: exclude_team_ids).each do |t|
        next unless t.projects.empty?

        ids << t.id
        Rails.logger.info "Requesting deletion for team '#{t.slug}' (ID: #{t.id})"
        TeamsService.destroy!(t)
      end

      delete_audits_for 'Team', ids
      delete_associated_audits_for 'Team', ids
    end

    def delete_audits_for(auditable_type, auditable_ids)
      Audit.where(auditable_type: auditable_type, auditable_id: auditable_ids).each(&:delete)
    end

    def delete_associated_audits_for(associated_type, associated_ids)
      Audit.where(associated_type: associated_type, associated_id: associated_ids).each(&:delete)
    end
  end
end
