FactoryBot.define do
  factory :credential do
    kind { 'robot' }
    sequence :name do |n|
      "credential-#{n}"
    end
    value { SecureRandom.alphanumeric }

    # NOTE: this factory will not produce a valid model object out of the box
    # - you will need to set the `integration` and `owner` associations when using it.
  end
end
