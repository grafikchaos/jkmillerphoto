environment ENV['RAILS_ENV']

pidfile 'tmp/pids/puma.pid'
state_path 'tmp/pids/puma.state'
bind 'unix:///tmp/puma-jkmillerphoto.sock'
stdout_redirect 'log/puma.log', 'log/puma_err.log'

threads 1, 6
workers 3


preload_app!

on_worker_boot do
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end
end
