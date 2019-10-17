Rails.application.config.base_url = ENV.fetch('BASE_URL') { raise 'BASE_URL missing from env' }

Rails.application.config.version = ENV.fetch('VERSION', 'not-set')
