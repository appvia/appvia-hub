module SyncIntegrationTeamService
  TEAM_PREFIX = '[Hub]'.freeze

  class << self
    def build_team_name(slug)
      "#{TEAM_PREFIX} #{slug}"
    end

    def sync_team(integration, team)
      name = build_team_name team.slug

      case integration.provider_id
      when 'git_hub'
        agent = agent_for integration

        agent.create_team name, team.description

        team.memberships.each do |membership|
          sync_team_membership integration, membership
        end
      end

      true
    end

    def remove_team(integration, team_slug)
      name = build_team_name team_slug

      case integration.provider_id
      when 'git_hub'
        agent = agent_for integration

        agent.delete_team name
      end

      true
    end

    def sync_team_membership(integration, team_membership)
      team = team_membership.team
      user = team_membership.user

      name = build_team_name team.slug

      case integration.provider_id
      when 'git_hub'
        # If the user has an existing identity for this integration, then we
        # can add them to the GitHub team. Otherwise, the user will only get
        # added once they connect up their GitHub identity.
        identity = user.identities.find_by integration_id: integration.id
        if identity.present?
          agent = agent_for integration

          agent.add_user_to_team name, identity.external_username
        end
      end

      true
    end

    def remove_team_membership(integration, team_slug, external_username)
      name = build_team_name team_slug

      case integration.provider_id
      when 'git_hub'
        agent = agent_for integration

        agent.remove_user_from_team name, external_username
      end

      true
    end

    private

    def agent_for(integration)
      AgentsService.get integration.provider_id, integration.config
    end
  end
end
