load 'deploy' if respond_to?(:namespace) # cap2 differentiator

# Load third party
Dir['vendor/gems/*/recipes/*.rb','vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }

# Uncomment if you are using Rails' asset pipeline
load 'deploy/assets'

# load 'config/deploy' # remove this line to skip loading any of the default tasks


# --------------------------------------------
# Define required Gems/libraries
# --------------------------------------------
require 'capistrano/ext/multistage'
require 'bundler/capistrano'
# require 'puma/capistrano'

# --------------------------------------------
# CALLBACKS: Define which order tasks should
# be called in and which tasks are default
# --------------------------------------------
# before "deploy", "deploy:check_revision"
after "deploy:setup", "deploy:setup_config"
after "deploy:update_code", "deploy:migrate"
after "deploy:finalize_update", "deploy:symlink_config"
after "deploy", "deploy:cleanup" # keep only the last 5 releases
after "deploy:cleanup", "deploy:restart"

# --------------------------------------------
# :stages HAS TO BE DEFINED BEFORE
# REQUIRING capsitrano/ext/multistage LIBRARY
# --------------------------------------------
set :application, "jkmillerphoto.com"
set :stages, %w(staging production)
set :default_stage, "staging"

# --------------------------------------------
# SSH login credentials
# --------------------------------------------
server "192.241.254.31", :web, :app, :db, primary: true

# show password requests on windows
# (http://weblog.jamisbuck.org/2007/10/14/capistrano-2-1)
default_run_options[:pty] = true
default_run_options[:shell] = '/bin/bash'
# set :shell, '/bin/bash'


set :user, "deploy"
set :port, 33322

# Deploy to file path
set(:deploy_to)  { "/var/www/#{application}/#{stage}" }

# runtime dependencies
depend :remote, :gem, "bundler", '>= 1.3.5' # gotta have the bundler to run anything

# --------------------------------------------
# Source Control
# --------------------------------------------
set :scm, "git"
set :repository, "git@github.com:grafikchaos/jkmillerphoto.git"
set :git_enable_submodules, 1
set :repository_cache, 'git_cache'
set :deploy_via, :remote_cache
set :copy_exclude, [".git*", ".DS_Store", "*.sublime*", "LICENSE*", "RELEASE*", "nbproject", "*.md", "Guardfile", 'Vagrantfile', 'Capfile', 'config/deploy', 'config/unicorn*', 'config/nginx*', 'config/database.yml*', 'config/cucumber.yml', 'config/application.yml*', 'test', 'spec', 'features', '.rspec']



# Define which directories are shared between releases
#
#   Example - Capistrano defaults to:
#     _cset :shared_children,   %w(public/system log tmp/pids)
set :shared_children, %w(public/system log tmp/pids tmp/sockets public/uploads)

# --------------------------------------------
# Database
# --------------------------------------------
set :dbuser,  "jkmiller_user"
set :dbpass,  proc{Capistrano::CLI.password_prompt("Database password for '#{dbuser}':")}
set :dbname,  proc{text_prompt("Database name: ")}


# --------------------------------------------
# RAKE configuration
# --------------------------------------------
set :rake, "bundle exec rake" # sets the rake command to use bundler

# --------------------------------------------
# Puma/Foreman configuration
# --------------------------------------------
set(:puma_sock) { "unix://#{shared_path}/sockets/puma.sock" }
set(:puma_control) { "unix://#{shared_path}/sockets/pumactl.sock" }
set(:puma_state) { "#{shared_path}/sockets/puma.state" }
set(:puma_log) { "#{shared_path}/log/puma-#{stage}.log" }

namespace :puma do
  desc "Start the application"
  task :start do
    run "cd #{current_path} && RAILS_ENV=#{stage} && bundle exec puma -b '#{puma_sock}' -e #{stage} -t2:4 --control '#{puma_control}' -S #{puma_state} >> #{puma_log} 2>&1 &", :pty => false
  end

  desc "Stop the application"
  task :stop do
    run "cd #{current_path} && RAILS_ENV=#{stage} && bundle exec pumactl -S #{puma_state} stop"
  end

  desc "Restart the application"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "cd #{current_path} && RAILS_ENV=#{stage} && bundle exec pumactl -S #{puma_state} restart"
  end

  desc "Status of the application"
  task :status, :roles => :app, :except => { :no_release => true } do
    run "cd #{current_path} && RAILS_ENV=#{stage} && bundle exec pumactl -S #{puma_state} stats"
  end
end


# --------------------------------------------
# Override Tasks
# --------------------------------------------
namespace :deploy do
  desc <<-DESC
    Creates stubbed database.yml file in the shared path. You'll be responsible \
    for ensuring the database credentials are correct
  DESC
  task :setup_config, roles: :app do
    run "mkdir -p #{shared_path}/config"
    ["database.yml", "application.yml"].each do |config_file|
      if File.file?("#{shared_path}/config/#{config_file}")
        puts "SKIPPING '#{config_file}' in 'deploy:setup_config' BECAUSE '#{config_file}' ALREADY EXISTS AT '#{shared_path}/config'"
      else
        put File.read("config/#{config_file.gsub('yml', 'example.yml')}"), "#{shared_path}/config/#{config_file}"
        puts "Now edit the #{config_file} in #{shared_path}/config."
      end
    end
  end

  task :symlink_config, roles: :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/config/application.yml #{release_path}/config/application.yml"
  end

  %w(start stop restart).each do |command|
    desc "#{command} the application"
    task command, roles: :app do
      puma.send(command.to_sym)
    end
  end
end

# --------------------------------------------
# Backups Config
# --------------------------------------------
# Backups Path
_cset(:backups_path)    { File.join(deploy_to, "backups") }
_cset(:tmp_backups_path)  { File.join("#{backups_path}", "tmp") }
_cset(:backups)         { capture("ls -x #{backups_path}", :except => { :no_release => true }).split.sort }

# Define which files or directories you want to exclude from being backed up
_cset(:backup_exclude)  {
  [
    "var/", "config/deploy", "config/database.yml.dist", "tmp/cache", "tmp/pids", "tmp/sessions",
    "tmp/sockets", "tmp/webrat-*.html", "webrat.log", "certs", '.svn', '.git', 'Capfile'
  ]
}
set :exclude_string,  ''

# Define the default number of backups to keep
set :keep_backups, 10

# Override the default REASON and UNTIL variables for deploy:web:disable
ENV['REASON'] = "Routine Maintenance - Updating Application"
ENV['UNTIL']  = "within a few minutes. Please refresh the page in a few minutes."


# --------------------------------------------
# Backup tasks
# --------------------------------------------
namespace :backup do
  desc "Perform a backup of web and database files"
  task :default, :roles => :web, :except => { :no_release => true } do
    db
    web
  end

  desc <<-DESC
    Requires the rsync package to be installed.

    Performs a file-level backup of the application and any assets \
    from the shared directory that have been symlinked into the \
    applications root or sub-directories.

    You can specify which files or directories to exclude from being \
    backed up (i.e., log files, sessions, cache) by setting the \
    :backup_exclude variable
        set(:backup_exclude) { [ "var/", "tmp/", logs/debug.log ] }
  DESC
  task :web, :roles => :web do
    if previous_release
      puts "Backing up web files (user uploaded content and previous release)"

      if !backup_exclude.nil? && !backup_exclude.empty?
        logger.debug "processing backup exclusions..."
        backup_exclude.each do |pattern|
          exclude_string << "--exclude '#{pattern}' "
        end
        logger.debug "Exclude string = #{exclude_string}"
      end

      # Copy the previous release to the /tmp directory
      logger.debug "Copying previous release to the #{tmp_backups_path}/#{release_name} directory"
      run "rsync -avzrtpL #{exclude_string} #{current_path}/ #{tmp_backups_path}/#{release_name}/"
      # create the tarball of the previous release
      set :archive_name, "release_B4_#{release_name}.tar.gz"
      logger.debug "Creating a Tarball of the previous release in #{backups_path}/#{archive_name}"
      run "cd #{tmp_backups_path} && tar -cvpf - ./#{release_name}/ | gzip -c --best > #{backups_path}/#{archive_name}"

      # remove the the temporary copy
      logger.debug "Removing the tempory copy"
      run "rm -rf #{tmp_backups_path}/#{release_name}"
    else
      logger.important "no previous release to backup; backup of files skipped"
    end
  end

  desc "Perform a backup of database files"
  task :db, :roles => :db, :except => { :no_release => true }  do
    puts "Backing up the database now and putting dump file in the previous release directory"
    # define the filename (include the current_path so the dump file will be within the dirrectory)
    filename = "#{current_path}/#{dbname}_dump-#{Time.now.to_s.gsub(/ /, "_")}.sql.gz"
    # dump the database for the proper environment
    run "mysqldump -u #{dbuser} -p #{dbname} | gzip -c --best > #{filename}" do |ch, stream, out|
      ch.send_data "#{dbpass}\n" if out =~ /^Enter password:/
    end
  end

  desc <<-DESC
    Clean up old backups. By default, the last 10 backups are kept on each \
    server (though you can change this with the keep_backups variable). All \
    other backups are removed from the servers. By default, this \
    will use sudo to clean up the old backups, but if sudo is not available \
    for your environment, set the :use_sudo variable to false instead.
  DESC
  task :cleanup, :except => { :no_release => true } do
    count = fetch(:keep_backups, 10).to_i
    if count >= backups.length
      logger.important "no old backups to clean up"
    else
      logger.info "keeping #{count} of #{backups.length} backups"

      archives = (backups - backups.last(count)).map { |backup|
        File.join(backups_path, backup) }.join(" ")

      run "#{sudo} rm -rf #{archives}"
    end
  end

  desc "Setup backup directory for database and web files"
  task :setup_backup, :except => { :no_release => true } do
    run "mkdir -p #{backups_path} && mkdir -p #{tmp_backups_path}"
  end
end


# --------------------------------------------
# Utility Tasks
# --------------------------------------------
# Test to see if a file exists by providing
# the full path to the expected file location
def remote_file_exists?(full_path)
  'true' ==  capture("if [ -e #{full_path} ]; then echo 'true'; fi").strip
end

# Test to see if a directory exists on a remote
# server by providing the full path to the expected
# directory
#
# Params:
#   +dir_path+
def remote_dir_exists?(dir_path)
  'true' == capture("if [[ -d #{dir_path} ]]; then echo 'true'; fi").strip
end
