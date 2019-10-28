class Cluster < ApplicationRecord
  include HasResourceStatus
  include SluggedAttribute

  audited associated_with: :team

  belongs_to :team,
    -> { readonly },
    inverse_of: :clusters

  belongs_to :crd,
    -> { readonly },
    inverse_of: false

  belongs_to :created_by,
    -> { readonly },
    class_name: 'User',
    inverse_of: false

  slugged_attribute :name,
    presence: true,
    uniqueness: { scope: :team_id },
    readonly: true

  attr_readonly :created_by_id, :team_id, :crd_id

  def descriptor
    name
  end

  def deleteable?
    !pending? && !active? && !failed?
  end
end
