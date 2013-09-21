environment ENV['RAILS_ENV']
threads 1, 6

workers 3
preload_app!

on_worker_boot do
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end
end

# workers 1
# on_worker_boot do
#   require "active_record"
#   cwd = File.dirname(__FILE__)+"/.."
#   puts cwd
#   ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished
#   ActiveRecord::Base.establish_connection(ENV["DATABASE_URL"] || YAML.load_file("#{cwd}/config/database.yml")[environment])
#   ActiveRecord::Base.verify_active_connections!
# end
