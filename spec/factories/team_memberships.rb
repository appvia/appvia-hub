FactoryBot.define do
  factory :team_membership do
    team
    user

    trait :admin do
      role { 'admin' }
    end
  end
end
