class ActivityService
  DEFAULT_PAGE_SIZE = 20
  DEFAULT_TIME_WINDOW = 1.month

  # These must match what gets shown in view(s)
  AUDITABLE_TYPES_AND_ACTIONS = {
    'User' => %w[create update],
    'Team' => %w[create destroy],
    'TeamMembership' => %w[create update destroy],
    'Project' => %w[create destroy],
    'Resource' => %w[request_create update request_delete destroy]
  }.freeze

  USER_FILTERED_TYPES = %w[Team Project].freeze

  def overall(user)
    user_team_ids = user.admin? ? [] : user.teams.pluck(:id)
    user_project_ids = if user.admin?
                         []
                       else
                         Project
                           .where(team_id: user_team_ids)
                           .pluck(:id)
                       end

    fill(DEFAULT_PAGE_SIZE) do |page, per_page|
      items = fetch(Audit.all, page, per_page).entries

      filtered_items = if user.admin?
                         items
                       else
                         filter_audits(items, user_team_ids, user_project_ids)
                       end

      [
        items.empty? || items.length < DEFAULT_PAGE_SIZE,
        filtered_items
      ]
    end
  end

  def for_team(team)
    fill(DEFAULT_PAGE_SIZE) do |page, per_page|
      items = fetch(team.own_and_associated_audits, page, per_page).entries

      [
        items.empty? || items.length < DEFAULT_PAGE_SIZE,
        items
      ]
    end
  end

  def for_project(project)
    fill(DEFAULT_PAGE_SIZE) do |page, per_page|
      items = fetch(project.own_and_associated_audits, page, per_page).entries

      [
        items.empty? || items.length < DEFAULT_PAGE_SIZE,
        items
      ]
    end
  end

  private

  def fill(size)
    items = []
    page = 0
    finished = false

    while items.length < size && !finished
      page += 1
      finished, new_items = yield page, size
      items += new_items
    end

    items
  end

  def fetch(initial_scope, page, per_page)
    initial_scope
      .merge(allowed_types_query)
      .where('created_at >= ?', DEFAULT_TIME_WINDOW.ago.utc)
      .limit(per_page)
      .offset((page - 1) * per_page)
      .order(created_at: :desc)
  end

  def allowed_types_query
    conditions = AUDITABLE_TYPES_AND_ACTIONS.map do |k, v|
      Audit.where(auditable_type: k, action: v)
    end
    head, *tail = conditions
    tail.reduce(head) { |acc, q| acc.or(q) }
  end

  def filter_audits(audits, allowed_teams, allowed_projects)
    audits.select do |a|
      next true unless USER_FILTERED_TYPES.include?(a.auditable_type) ||
                       USER_FILTERED_TYPES.include?(a.associated_type)

      # Since we use UUIDs for IDs, we can assume a very tiny chance of clashes
      # across different db records.
      id = a.associated_id || a.auditable_id
      allowed_teams.include?(id) || allowed_projects.include?(id)
    end
  end
end
