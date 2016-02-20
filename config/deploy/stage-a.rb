server 'argo-stage-a.stanford.edu', user: 'lyberadmin', roles: %w(web db app)

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, 'staging'

set :deploy_to, '/opt/app/lyberadmin/argo'

set :delayed_job_workers, 10
