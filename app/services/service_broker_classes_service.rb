class ServiceBrokerClassesService
  attr_reader :service_classes

  def initialize(agent)
    @agent = agent
    load_service_classes
  end

  def service_class(class_name)
    @service_classes.find { |o| o.metadata.name == class_name }
  end

  def service_plans(class_name)
    service_class(class_name)&.plans || []
  end

  def service_plan(class_name, plan_name)
    service_plans(class_name).find { |p| p.metadata.name == plan_name }
  end

  def service_plan_schema(class_name, plan_name)
    schema = service_plan(class_name, plan_name)&.spec&.instanceCreateParameterSchema
    schema.to_hash.deep_stringify_keys if schema.present?
  end

  def service_class_plan_names(class_name, plan_name)
    service_class_names(class_name).merge service_plan_names(class_name, plan_name)
  end

  def generate_service_class_select_options
    @service_classes.collect { |c| [c.spec.externalMetadata.displayName, c.metadata.name] }
  end

  def generate_service_plans_select_options(class_name)
    service_plans(class_name).collect { |p| ["#{p.spec.externalMetadata.displayName} - #{p.spec.description}", p.metadata.name] }
  end

  private

  def load_service_classes
    @service_classes = @agent.get_options
  end

  def service_class_names(class_name)
    selected_class = service_class class_name
    return {} if selected_class.nil?

    {
      class_name: selected_class.metadata.name,
      class_external_name: selected_class.spec.externalName,
      class_display_name: selected_class.spec.externalMetadata.displayName
    }
  end

  def service_plan_names(class_name, plan_name)
    selected_plan = service_plan(class_name, plan_name)
    return {} if selected_plan.nil?

    {
      plan_name: selected_plan.metadata.name,
      plan_external_name: selected_plan.spec.externalName,
      plan_display_name: selected_plan.spec.externalMetadata.displayName
    }
  end
end
