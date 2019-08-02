FactoryBot.define do
  factory :admin_task, class: 'Admin::Task' do
    status { Admin::Task.statuses.keys.first }
    association :requested_by, factory: :user
  end
end
