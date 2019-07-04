module Resources
  class CreateGitHubCodeRepoService
    IMPORT_WAIT_ATTEMPTS = 15
    IMPORT_WAIT_CHECK_TIMEOUT = 30.seconds.to_i
    IMPORT_WAIT_DELAY = 20.seconds.to_i
    IMPORT_WAIT_FINISH_STATUSES = %w[
      complete
      auth_failed
      error
      detection_needs_auth
      detection_found_nothing
      detection_found_multiple
    ].freeze

    def initialize(agent)
      @agent = agent
    end

    def call(resource, config)
      all_team_id = config['all_team_id']

      should_enforce_best_practices = config['enforce_best_practices']

      should_auto_init = should_enforce_best_practices && resource.template_url.blank?

      create_result = @agent.create_repository(
        resource.name,
        team_id: all_team_id,
        auto_init: should_auto_init
      )

      resource.private = create_result.private
      resource.full_name = create_result.full_name
      resource.url = create_result.html_url
      resource.enforce_best_practices = should_enforce_best_practices

      import_from_template_if_needed resource

      @agent.apply_best_practices(resource.full_name) if should_enforce_best_practices
    end

    private

    def import_from_template_if_needed(resource)
      return if resource.template_url.blank?

      user_auth_token = resource
        .requested_by
        .identities
        .find_by(integration_id: resource.integration_id)
        &.access_token

      result = @agent.import_from_template(
        resource.full_name,
        resource.template_url,
        user_auth_token: user_auth_token
      )

      git_hub_client = result[:client]

      wait = Wait.new(
        attempts: IMPORT_WAIT_ATTEMPTS,
        timeout: IMPORT_WAIT_CHECK_TIMEOUT,
        delay: IMPORT_WAIT_DELAY,
        debug: Rails.env.development?
      )

      wait.until do
        result = git_hub_client.source_import_progress(resource.full_name)
        IMPORT_WAIT_FINISH_STATUSES.include? result['status']
      end
    end
  end
end
