module TeamsHelper
  def team_icon
    icon 'user-friends'
  end

  def delete_team_link(team, css_class: nil)
    return unless can?(:destroy, team)

    link_to 'Delete',
      team_path(team),
      method: :delete,
      class: css_class,
      data: {
        confirm: 'Are you sure you want to delete this team permanently?',
        title: "Delete team: #{team.slug}",
        verify: team.slug,
        verify_text: "Type '#{team.slug}' to confirm"
      },
      role: 'button'
  end

  def delete_team_membership_link(team, user, css_class: nil)
    link_to 'Remove from team',
      team_membership_path(team, user),
      method: :delete,
      class: css_class,
      data: {
        confirm: [
          'Are you sure you want to remove this team member from the team?',
          'Note that they will lose access to all spaces and resources within this team.'
        ].join(' '),
        title: "Remove team member: #{user.email}",
        verify: 'yes',
        verify_text: "Type 'yes' to confirm"
      },
      role: 'button'
  end

  def update_team_membership_role_link(text, team, user, role, css_class: nil)
    link_to text,
      team_membership_path(team, user),
      remote: true,
      method: :put,
      class: css_class,
      data: {
        params: { role: role }.to_param,
        'disable-with': 'Processing...',
        turbolinks: false,
        confirm: 'Are you sure you want to update the role for this team member?',
        title: "Update role for team member: #{user.email}",
        verify: 'yes',
        verify_text: "Type 'yes' to confirm"
      },
      role: 'button'
  end
end
