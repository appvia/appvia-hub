module TeamsHelper
  def team_icon
    icon 'user-friends'
  end

  def delete_team_link(team, css_class: nil)
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
end
