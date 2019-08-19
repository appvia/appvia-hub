module ProjectsHelper
  def project_icon
    icon 'cube'
  end

  def delete_project_link(project, css_class: nil)
    return unless can?(:destroy, project)

    if project.resources.count.positive?
      tag.span class: css_class do
        safe_join(
          [
            'Delete (unavailable)',
            icon_with_tooltip(
              'You can only delete this space once all resources are deleted from within it',
              css_class: 'ml-2',
              style: 'color: inherit'
            )
          ]
        )
      end
    else
      link_to 'Delete',
        project_path(project),
        method: :delete,
        class: css_class,
        data: {
          confirm: 'Are you sure you want to delete this space permanently?',
          title: "Delete space: #{project.slug}",
          verify: project.slug,
          verify_text: "Type '#{project.slug}' to confirm"
        },
        role: 'button'
    end
  end
end
