module SyncIntegrationTeamService
  TEAM_PREFIX = '[Hub]'.freeze

  class << self
    def sync_team(integration, team)
      case integration.provider_id
      when 'git_hub'
        agent = AgentsService.get integration.provider_id, integration.config

        agent.create_team(
          build_team_name(team.slug),
          team.description
        )

        team.memberships.each do |membership|
          sync_team_membership integration, membership
        end
      end
    end

    def remove_team(integration, team_slug)
      case integration.provider_id
      when 'git_hub'
        agent = AgentsService.get integration.provider_id, integration.config

        agent.delete_team build_team_name(team_slug)
      end
    end

    def sync_team_membership(integration, team_membership)
      team = team_membership.team
      user = team_membership.user

      case integration.provider_id
      when 'git_hub'
        # If the user has an existing identity for this integration, then we
        # can add them to the GitHub team. Otherwise, the user will only get
        # added once they connect up their GitHub identity.
        identity = user.identities.find_by integration_id: integration.id
        if identity.present?
          agent = AgentsService.get integration.provider_id, integration.config

          agent.add_user_to_team(
            build_team_name(team.slug),
            identity.external_username
          )
        end
      end
    end

    def remove_team_membership(integration, team_slug, external_username)
      case integration.provider_id
      when 'git_hub'
        agent = AgentsService.get integration.provider_id, integration.config

        agent.remove_user_from_team(
          build_team_name(team_slug),
          external_username
        )
      end
    end

    def build_team_name(slug)
      "#{TEAM_PREFIX} #{slug}"
    end
  end
end
