require 'thread'

module Elements
  class CompilerMiddleware
    CACHE_KEY = 'last_elements_compiler_run'

    def initialize(app)
      @app = app
      @mutex = Mutex.new
    end

    def call(env)
      if Rails.env.production?
        @mutex.synchronize do
          result = Elements::ElementDescriptor.select('MAX(updated_at) updated_at').first
          last_update = result.nil? ? nil : result.updated_at
          last_compile = Rails.cache.read(CACHE_KEY) || Time.now

          reload! if last_update.nil? || last_update < last_compile
        end
      end
      @app.call(env)
    end

    def reload!
      Rails.logger.info('Reloading elements')
      ::Elements::Types.reload!
      Rails.cache.write(CACHE_KEY, Time.now)
    end

  end
end
