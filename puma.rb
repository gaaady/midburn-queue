workers 0
threads_min = Integer(ENV["MIN_THREADS"] || 20)
threads_max = Integer(ENV["MAX_THREADS"] || 60)

tag 'midburn-queue'
threads threads_min, threads_max
preload_app!

rackup 'config.ru'