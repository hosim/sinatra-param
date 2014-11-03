require 'sinatra/base'
require 'sinatra/param/version'
require 'sinatra/param/core'
require 'date'
require 'time'

module Sinatra
  module Param
    Boolean = :boolean

    class InvalidParameterError < StandardError
      attr_accessor :param, :options
    end

    def param(name, type, options = {}, &block)
      Core.new(self, params).param(name, type, options, &block)
    rescue InvalidParameterError => ex
      raise ex if options[:raise] or
        (settings.raise_sinatra_param exceptions rescue false)

      error = "Invalid Parameter: #{ex.param}"
      if content_type and content_type.match(mime_type(:json))
        error = {message: error, errors: {name => ex.message}}.to_json
      end

      halt 400, error
    end

    def one_of(*names)
      count = 0
      names.each do |name|
        if params[name] and present?(params[name])
          count += 1
          next unless count > 1

          error = "Parameters #{names.join(', ')} are mutually exclusive"
          if content_type and content_type.match(mime_type(:json))
            error = {message: error}.to_json
          end

          halt 400, error
        end
      end
    end

    private

    # ActiveSupport #present? and #blank? without patching Object
    def present?(object)
      !blank?(object)
    end

    def blank?(object)
      object.respond_to?(:empty?) ? object.empty? : !object
    end
  end

  helpers Param
end
