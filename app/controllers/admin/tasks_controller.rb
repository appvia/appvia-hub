module Admin
  class TasksController < ApplicationController
    # GET /admin/tasks/new
    def new
      type = params.require(:type)
      type = "Admin::Tasks::#{type}" unless type.starts_with?('Admin::Tasks::')

      @admin_task = Admin::Task.new(type: type)

      case type
      when 'Admin::Tasks::CreateKubeCluster'
        cluster_creator = params.require(:cluster_creator)
        @admin_task.cluster_creator = cluster_creator
      end
    end

    # POST /admin/tasks
    def create
      type_specific_params = params[:admin_task].require(:type_params).permit!
      all_params = admin_task_params.merge(type_specific_params)

      @admin_task = Admin::Task.new all_params

      @admin_task.created_by = current_user

      if @admin_task.save
        Admin::TaskWorker.perform_async @admin_task.id

        redirect_to admin_create_path(autorefresh: true), notice: 'Task was successfully created.'
      else
        @cluster_creator_spec = CLUSTER_CREATORS_REGISTRY.get @admin_task.cluster_creator
        render :new
      end
    end

    # DELETE /admin/tasks/:id
    def destroy
      @admin_task = Admin::Task.find params[:id]

      if @admin_task.deleteable?
        @admin_task.destroy
        redirect_to admin_create_path, notice: 'Task successfully deleted.'
      else
        redirect_to admin_create_path, alert: 'Can\'t delete task.'
      end
    end

    private

    def admin_task_params
      params.require(:admin_task).permit(:type)
    end
  end
end
