module SluggedAttribute
  extend ActiveSupport::Concern

  SLUG_FORMAT_REGEX = '[a-z]+[a-z0-9\-]*'.freeze
  SLUG_FORMAT_TEXT = 'must start with a letter and can only contain lowercase letters, numbers and hyphens'.freeze

  class_methods do
    def slugged_attribute(attribute_name, presence:, uniqueness:, readonly:)
      validates attribute_name,
        presence: presence,
        uniqueness: uniqueness,
        format: {
          with: /\A#{SLUG_FORMAT_REGEX}\z/,
          message: SLUG_FORMAT_TEXT
        }

      attr_readonly attribute_name if readonly
    end
  end
end
