module Admin
  class CreateController < BaseController
    authorize_resource class: false

    def show
      @options = CLUSTER_CREATORS_REGISTRY.all
      @tasks = Admin::Tasks::CreateKubeCluster.all.order(updated_at: :desc)
    end
  end
end
