require 'middleman-core/cli'
require 'middleman-core/cli/build'
require 'contentful_middleman'
require 'middleman-core/profiling'
require 'middleman-s3_sync'
require 'goliath'
require 'git'

ENV['MM_ROOT'] = File.join(Dir.pwd, "src")
ENV['BUILD_INTERVAL'] ||= "30"

%w(GH_REPOSITORY GH_TOKEN AWS_ACCESS_KEY AWS_ACCESS_KEY AWS_SECRET_KEY).each do |args|
  raise ArgumentError.new("#{args} is missing!") unless ENV[args]
end

### Monkeypatching Middleman Extensions
### to clear all cached variables that
### might be standing in our way when
### using them in a long-running process
class Middleman::Cli::Build
  def self.reset_instance!
    @_shared_instance = nil
  end
end

module Middleman
  module S3Sync
    class << self
      def reset_files!
        %w(@bucket @bucket_files @paths @resources @remote_paths @local_paths @bucket_files @progress_bar @files_to_delete @files_to_create @files_to_ignore @files_to_update).each do |var|
          instance_variable_set(var, nil)
        end
      end
    end
  end
end

class DeferedBuild

  def initialize(address, port, config, status, logger)
    @logger = logger
    @status = status

    @status[:build] = 0
  end

  def run
    EM.add_periodic_timer(ENV['BUILD_INTERVAL'].to_i) do
      begin
        if @status[:build] > 0
          @logger.info( "Building due to #{@status[:build]} build triggers")
          EM.defer do
            @logger.info(repository.pull)

            Middleman::Cli::Build.new.build
            Middleman::Cli::Build.reset_instance!

            Middleman::Cli::S3Sync.new.s3_sync
            Middleman::S3Sync.reset_files!

            @logger.info( "done!")
          end
        end
      rescue SystemExit => e
        @logger.error("Keep on rolling! #{e.message}")
      ensure
        @status[:build] = 0
      end
    end
  end

  def repository
    Git.open ENV['MM_ROOT']
  rescue
    @logger.info("Cloning repository as it seems not to be there already!")
    Git.clone("https://#{ENV['GH_TOKEN']}@github.com/#{ENV['GH_REPOSITORY']}.git", "src")
  end

end

class Webhook < Goliath::API
  plugin DeferedBuild

  def response(env)
    status[:build] += 1

    [200, {}, "Our canon is loaded! Now let us take the work from here pal!"]
  end
end
