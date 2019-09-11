module Teams
  class BaseWorker
    include Sidekiq::Worker

    sidekiq_options queue: 'teams', retry: false
  end
end
