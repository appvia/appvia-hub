FactoryBot.define do
  factory :identity do
    user
    sequence :external_id do |n|
      "id-#{n}"
    end

    # NOTE: this factory will not produce a valid model object out of the box
    # - you will need to set the `integration` association when using it.
  end
end
