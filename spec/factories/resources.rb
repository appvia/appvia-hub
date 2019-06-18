FactoryBot.define do
  factory :resource do
    project
    status { Resource.statuses.keys.first }
    sequence :name do |n|
      "resource-#{n}"
    end

    factory :code_repo, class: 'Resources::CodeRepo' do
    end

    factory :docker_repo, class: 'Resources::DockerRepo' do
    end

    factory :kube_namespace, class: 'Resources::KubeNamespace' do
    end

    factory :monitoring_dashboard, class: 'Resources::MonitoringDashboard' do
      # NOTE: this factory will not produce a valid model object out of the box
      # - you will need to set the `parent` association yourself (to another
      # valid resource).
    end

    factory :logging_dashboard, class: 'Resources::LoggingDashboard' do
      # NOTE: this factory will not produce a valid model object out of the box
      # - you will need to set the `parent` association yourself (to another
      # valid resource).
    end
  end
end
