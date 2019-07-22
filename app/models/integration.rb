class Integration < ApplicationRecord
  include EncryptedConfigHashAttribute

  audited

  enum provider_id: PROVIDERS_REGISTRY.ids.each_with_object({}) { |id, acc| acc[id] = id }

  validates :name,
    presence: true,
    uniqueness: true

  validates :provider_id, presence: true

  validates :config, presence: true

  attr_readonly :provider_id

  validates :parent_ids,
    presence: true,
    if: :requires_a_parent?

  has_many :resources,
    dependent: :restrict_with_exception,
    inverse_of: :integration

  has_many :user_identities,
    class_name: 'Identity',
    dependent: :restrict_with_exception,
    inverse_of: :integration

  validate :check_parents

  def provider
    return if provider_id.blank?

    PROVIDERS_REGISTRY.get provider_id
  end

  def config_schema
    return nil if provider_id.blank?

    schema = PROVIDERS_REGISTRY.config_schemas[provider_id]

    raise "Missing config schema for provider '#{provider_id}'" if schema.blank?

    schema
  end

  def descriptor
    name
  end

  def parents
    self.class.where(id: parent_ids)
  end

  def children
    self.class.where('parent_ids @> ARRAY[?]::uuid[]', Array(id))
  end

  private

  def with_resource_type
    resource_type = ResourceTypesService.for_integration self

    yield resource_type if resource_type.present?
  end

  def requires_a_parent?
    with_resource_type do |resource_type|
      !resource_type[:top_level]
    end
  end

  def check_parents
    return if parent_ids.blank?

    # Ensure that the parent_ids actually point to real integrations
    all_exist = parent_ids.all? do |id|
      self.class.exists? id
    end
    errors.add(:parent_ids, 'an unknown Integration ID has been found in the parent IDs') unless all_exist

    # Ensure only the correct types of integrations can be linked together
    with_resource_type do |resource_type|
      all_allowed_provider_ids = parents.all? do |i|
        resource_type[:depends_on].include?(i.provider_id)
      end
      errors.add(:parent_ids, 'an invalid parent has been detected') unless all_allowed_provider_ids
    end

    # Ensure that a particular parent integration only has one of a particular
    # child integration type
    has_existing_child = parents.any? do |i|
      if i.children.size.zero?
        false
      else
        i.children.any? { |c| c.provider_id == provider_id }
      end
    end
    errors.add(:parent_ids, 'cannot link this to a parent as it already has a child integration of the same type') if has_existing_child
  end
end
