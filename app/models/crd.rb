class Crd < ApplicationRecord
  include AttrJson::Record

  attr_json_config default_container_attribute: :data

  validates :data, presence: true

  attr_json :apiVersion, :string
  validates :apiVersion, presence: true

  attr_json :kind, :string
  validates :kind, presence: true

  attr_json :metadata, ActiveModel::Type::Value.new
  validates :metadata, presence: true

  attr_json :spec, ActiveModel::Type::Value.new
  validates :spec, presence: true

  def name
    metadata['name']
  end
end
