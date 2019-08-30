module Admin
  module Tasks
    class CreateKubeCluster < Task
      attr_json :cluster_creator, :string
      validates :cluster_creator, presence: true

      attr_json :provision_options, ActiveModel::Type::Value.new
      validates :provision_options, presence: true

      attr_json :integrations, ActiveModel::Type::Value.new

      scope :by_cluster_creator, lambda { |id|
        where("data->>'cluster_creator' = ?", id)
      }

      scope :by_cluster_name, lambda { |name|
        where("data->'provision_options'->>'name' = ?", name)
      }

      before_validation :process_options
      validate :validate_options_match_schemas

      validate :validate_cluster_name_should_be_unique, on: :create

      def cluster_creator_spec
        return if cluster_creator.blank?

        CLUSTER_CREATORS_REGISTRY.get cluster_creator
      end

      def init_options
        encrypted_data['init_options']
      end

      def init_options=(data)
        self.encrypted_data = encrypted_data.merge('init_options' => data)
      end

      private

      def process_options
        spec = cluster_creator_spec

        return if spec.blank?

        ClusterCreatorsRegistry::OPTIONS_FIELDS.each do |f|
          data = send(f)

          next if data.blank?

          schema = CLUSTER_CREATORS_REGISTRY.schemas[cluster_creator][f]

          send(
            "#{f}=",
            JsonSchemaHelpers.ensure_data_types(data, schema).compact
          )
        end
      end

      def validate_options_match_schemas
        return if cluster_creator.blank?

        ClusterCreatorsRegistry::OPTIONS_FIELDS.each do |f|
          schema = CLUSTER_CREATORS_REGISTRY.schemas[cluster_creator][f]
          schema.validate! send(f)
        end
      rescue JsonSchema::AggregateError => e
        errors.add :options, e.to_s
      end

      def validate_cluster_name_should_be_unique
        return if cluster_creator.blank?

        cluster_name = provision_options['name']

        return if cluster_name.blank?

        already_exists = self.class.by_cluster_creator(cluster_creator).by_cluster_name(cluster_name).exists?

        return unless already_exists

        errors.add(
          :cluster_name,
          'already has a task - choose a different cluster name (or delete the other task first, if deletion is allowed for that task)'
        )
      end
    end
  end
end
