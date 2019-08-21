class Integration < ApplicationRecord
  include EncryptedConfigHashAttribute
  include Allocatable

  audited

  allocatable

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

  has_many :teams,
    through: :allocations,
    source: :allocation_receivable,
    source_type: Team.name

  has_many :resources,
    dependent: :restrict_with_exception,
    inverse_of: :integration

  has_many :user_identities,
    class_name: 'Identity',
    dependent: :restrict_with_exception,
    inverse_of: :integration

  validate :check_parents

  validate :check_teams

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

    ensure_parents_exist

    ensure_correct_parent_types

    ensure_parent_child_limits
  end

  def ensure_parents_exist
    # Ensure that the parent_ids actually point to real integrations
    all_exist = parent_ids.all? do |id|
      self.class.exists? id
    end
    errors.add(:parent_ids, 'an unknown Integration ID has been found in the parent IDs') unless all_exist
  end

  def ensure_correct_parent_types
    # Ensure only the correct types of integrations can be linked together
    with_resource_type do |resource_type|
      all_allowed_provider_ids = parents.all? do |i|
        resource_type[:depends_on].include?(i.provider_id)
      end
      errors.add(:parent_ids, 'an invalid parent has been detected') unless all_allowed_provider_ids
    end
  end

  def ensure_parent_child_limits
    # Ensure that a particular parent integration only has one of a particular
    # child integration type
    has_existing_child = parents.any? do |i|
      if i.children.size.zero?
        false
      else
        i.children.any? do |c|
          # Ignore the current integration
          is_self = c.id == id
          !is_self && c.provider_id == provider_id
        end
      end
    end
    errors.add(:parent_ids, 'cannot link this to a parent as it already has a child integration of the same type') if has_existing_child
  end

  def check_teams
    # Shouldn't be able to allocate teams to this integration if it's meant to be a dependent
    return unless requires_a_parent?
    return if team_ids.blank?

    errors.add(
      :teams,
      [
        'not allowed to be allocated to any teams as this is meant to be a',
        'dependent integration that inherits it\'s allocations from it\'s parent(s)'
      ].join(' ')
    )
  end
end
