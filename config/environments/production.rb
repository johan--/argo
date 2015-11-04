require 'active_support/cache/dalli_store'
require 'action_dispatch/middleware/session/dalli_store'

Argo::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  config.assets.compress = Settings.APPLICATION.ASSETS.COMPRESS

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = Settings.APPLICATION.CACHE_CLASSES
  config.perform_caching = true
  config.cache_store = :dalli_store, { namespace: Settings.CACHE_STORE_NAME }
  config.cache_store.logger.level = Logger::WARN
  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  config.middleware.use(Rack::Webauth)

  unless Settings.APPLICATION.ASSETS.PRECOMPILE.empty?
    config.assets.precompile += Settings.APPLICATION.ASSETS.PRECOMPILE
  end

  Argo.configure do
    reindex_on_the_fly      Settings.REINDEX_ON_FLY
    date_format_str         Settings.DATE_FORMAT_STR
    urls do
      mdtoolkit             Settings.MDTOOLKIT_URL
      purl                  Settings.PURL_URL
      stacks                Settings.STACKS_URL
      stacks_file           Settings.STACKS_FILE_URL
      dor_services          Settings.DOR_SERVICES_URL
      workflow              Settings.WORKFLOW_URL
      dpg                   Settings.DPG_URL
      robot_status          Settings.ROBOT_STATUS_URL
      modsulator            Settings.MODSULATOR_URL
      normalizer            Settings.NORMALIZER_URL
      spreadsheet           Settings.SPREADSHEET_URL
    end
    bulk_metadata_directory Settings.BULK_METADATA.DIRECTORY # Directory for storing bulk metadata job info
    bulk_metadata_log       Settings.BULK_METADATA.LOG       # Bulk metadata log file
    bulk_metadata_csv_log   Settings.BULK_METADATA.CSV_LOG   # Bulk metadata log file in CSV format for end users
    bulk_metadata_xml       Settings.BULK_METADATA.XML       # Bulk metadata XML output file
  end

  # the following config statement gets us two important things on each log line:
  # 1) unique IDs per request, so that it's easier to correlate
  # logging statements associated with a given request when multiple
  # simultaneous requests have interleaved log statements.
  # 2) time stamps on each log statement, because knowing when something
  # got logged is quite nice.
  # (declared after Argo.configure since it uses one of those params)
  config.log_tags = [:uuid, proc {Time.zone.now.strftime(Argo::Config.date_format_str)}]
end