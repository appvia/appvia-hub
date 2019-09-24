module ActivityHelper
  def activity_entry(icon, timestamp)
    tag.li class: 'list-group-item' do
      concat(tag.span(local_time_ago(timestamp), class: 'time-ago ml-2'))
      concat(icon)
      yield
    end
  end

  def activity_team_membership_user(audit)
    user = if audit.auditable.present?
             audit.auditable.user
           elsif audit.audited_changes.key?('user_id')
             User.find_by id: audit.audited_changes['user_id']
           end

    if user
      "user #{user.email}"
    else
      'an unknown user (removed from the hub)'
    end
  end
end
