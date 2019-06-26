module ApplicationHelper
  def crisp_chat
    crisp_website_id = SettingsService.get 'crisp_website_id'

    return if crisp_website_id.blank?

    safe_join(
      [
        raw( # rubocop:disable Rails/OutputSafety
          <<-SCRIPT
          <script type="text/javascript">
            window.$crisp=[];window.CRISP_WEBSITE_ID="#{crisp_website_id}";(function(){d=document;s=d.createElement("script");s.src="https://client.crisp.chat/l.js";s.async=1;d.getElementsByTagName("head")[0].appendChild(s);})();
          </script>
          SCRIPT
        )
      ]
    )
  end

  def show_requires_setup?
    controller.controller_name != 'integrations' &&
      Integration.count.zero?
  end

  def icon(name, size: '1x', css_class: [], title: nil, data_attrs: nil)
    tag.i '',
      class: ['fas', "fa-#{name}", "fa-#{size}"] + Array(css_class),
      title: title,
      data: data_attrs
  end

  def brand_icon(name, size: '1x', css_class: [], title: nil, data_attrs: nil)
    tag.i '',
      class: ['fab', "fa-#{name}", "fa-#{size}"] + Array(css_class),
      title: title,
      data: data_attrs
  end

  def icon_with_tooltip(text, icon_name: 'question-circle', css_class: [])
    icon icon_name,
      css_class: css_class,
      title: text,
      data_attrs: {
        toggle: 'tooltip'
      }
  end

  def label_with_tooltip(label, tooltip_text)
    # rubocop:disable Rails/OutputSafety
    raw(
      [
        label,
        icon_with_tooltip(tooltip_text)
      ].join(' ')
    )
    # rubocop:enable Rails/OutputSafety
  end
end
