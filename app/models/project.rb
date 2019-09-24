class Project < ApplicationRecord
  include SluggedAttribute
  include FriendlyId

  audited associated_with: :team

  belongs_to :team

  has_many :integration_overrides,
    dependent: :destroy,
    inverse_of: :project

  has_many :resources,
    -> { includes :integration },
    dependent: :restrict_with_exception,
    inverse_of: :project

  has_many :code_repos,
    class_name: 'Resources::CodeRepo',
    dependent: :restrict_with_exception

  has_many :docker_repos,
    class_name: 'Resources::DockerRepo',
    dependent: :restrict_with_exception

  has_many :kube_namespaces,
    class_name: 'Resources::KubeNamespace',
    dependent: :restrict_with_exception

  has_many :service_catalog_instances,
     class_name: 'Resources::ServiceCatalogInstance',
     dependent: :restrict_with_exception

  slugged_attribute :slug,
    presence: true,
    uniqueness: true,
    readonly: true

  friendly_id :slug

  validates :name, presence: true

  attr_readonly :team_id

  def descriptor
    slug
  end
end
