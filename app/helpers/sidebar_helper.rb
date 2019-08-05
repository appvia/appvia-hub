module SidebarHelper
  def nav_item(text, path, icon: nil)
    link_classes = %w[nav-link text-nowrap]
    is_active = current_page? path
    link_classes << 'active' if is_active

    link_to path, class: link_classes do
      concat(icon) if icon
      concat(tag.span(text))
      concat(tag.span('(current)', class: 'sr-only')) if is_active
    end
  end

  def nav_list_item(text, path, icon: nil)
    tag.li class: 'nav-item' do
      nav_item text, path, icon: icon
    end
  end
end
