class Project < ApplicationRecord
  include SluggedAttribute
  include FriendlyId

  audited

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

  slugged_attribute :slug,
    presence: true,
    uniqueness: true,
    readonly: true

  friendly_id :slug

  validates :name, presence: true

  def descriptor
    slug
  end
end
