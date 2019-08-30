module Admin
  class CreateController < BaseController
    def show
      @options = CLUSTER_CREATORS_REGISTRY.all
      @tasks = Admin::Tasks::CreateKubeCluster.all.order(updated_at: :desc)
    end
  end
end
