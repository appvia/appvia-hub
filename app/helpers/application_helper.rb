module ApplicationHelper
  def show_requires_setup?
    controller.controller_name != 'integrations' &&
      Integration.count.zero?
  end

  def nav_item(text, path, icon_name: nil)
    link_classes = ['nav-link', 'text-nowrap']
    is_active = current_page? path
    link_classes << 'active' if is_active

    tag.li class: 'nav-item' do
      link_to path, class: link_classes do
        concat(icon(icon_name)) if icon_name
        concat(tag.span(text))
        concat(tag.span('(current)', class: 'sr-only')) if is_active
      end
    end
  end

  def icon(name, size: '1x', title: nil, data_attrs: nil)
    tag.i '', class: "fas mr-2 fa-fw fa-#{name} fa-#{size}", title: title, data: data_attrs
  end

  def brand_icon(name, size: '1x', title: nil, data_attrs: nil)
    tag.i '', class: "fab mr-2 fa-fw fa-#{name} fa-#{size}", title: title, data: data_attrs
  end
end
