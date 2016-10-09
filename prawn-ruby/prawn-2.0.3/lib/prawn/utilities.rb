# encoding: utf-8

# utilities.rb : General-purpose utility classes which don't fit anywhere else

# Removed thread awareness for rb2py

module Prawn

  class SynchronizedCache
    def initialize
      @cache = {}
    end

    def [](key)
      @cache[key]
    end

    def []=(key, value)
      @cache[key] = value 
    end
  end

  class ThreadLocalCache
    def initialize
      @cache = {}
    end

    def [](key)
      @cache[key]
    end

    def []=(key, value)
      @cache[key] = value 
    end
  end
end
