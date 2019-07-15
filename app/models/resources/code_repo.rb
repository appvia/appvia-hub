module Resources
  class CodeRepo < Resource
    attr_json :private, :boolean
    attr_json :full_name, :string
    attr_json :url, :string
    attr_json :enforce_best_practices, :boolean, default: false
    attr_json :template_url, :string
  end
end
