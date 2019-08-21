class IntegrationOverridesService
  def overrideable_integrations(project)
    TeamIntegrationsService
      .get(project.team)
      .sort_by(&:provider_id)
      .each_with_object([]) do |i, acc|
        provider = i.provider

        overridable_properties = provider['config_spec']['properties'].select do |_k, v|
          v['overridable'] == true
        end

        next if overridable_properties.empty?

        acc << {
          integration: i,
          properties: overridable_properties
        }
      end
  end

  def update!(project, overrides)
    overrides.each do |(id, config)|
      integration = Integration.find id

      integration_override = project
        .integration_overrides
        .find_or_initialize_by(integration_id: integration.id)

      # Empty config values indicate no overriding required
      integration_override.config = config.select { |_k, v| v.present? }

      integration_override.save!
    end
  end

  def effective_config_for(integration, project)
    original_config = integration.config

    integration_override = project
      .integration_overrides
      .find_by(integration_id: integration.id)

    return original_config if integration_override.nil?

    original_config.merge integration_override.config
  end
end
