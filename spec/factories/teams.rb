FactoryBot.define do
  factory :team do
    sequence :name do |n|
      "Team #{n}"
    end
    sequence :slug do |n|
      "team-#{n}"
    end
  end
end
