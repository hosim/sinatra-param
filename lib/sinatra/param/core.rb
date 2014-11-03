# -*- coding: utf-8 -*-
require 'sinatra/param/coercer'
require 'sinatra/param/validator'

module Sinatra
  module Param
    class Core
      def initialize(requester, params)
        @requester = requester
        @params = params
      end

      def param(name, type, options={}, &block)
        value = @params[name.to_s]
        return unless @params.member?(name.to_s) or
          present?(options[:default]) or options[:required]

        value = coerce(value, type, options)
        value = apply_default_value(value, options.delete(:default))
        value = apply_transformation(value, options.delete(:transform))
        validate!(value, options)
        @params[name.to_s] = value
        if block_given? and value.respond_to?(:[])
          (value.is_a?(Array) ? value : [value]).each do |v|
            self.class.new(@requester, v).instance_eval(&block)
          end
        end
      rescue InvalidParameterError => ex
        ex.param = ex.param ? [name, ex.param].join('.') : name
        ex.options ||= options
        raise ex
      end

      private
      def present?(object)
        ! blank?(object)
      end

      def blank?(object)
        object.respond_to?(:empty?) ? object.empty? : ! object
      end

      def apply_default_value(value, option)
        if value.nil? and option
          option.respond_to?(:call) ? option.call : option
        else
          value
        end
      end

      def apply_transformation(value, option)
        return option.to_proc.call(value) if value and option
        value
      end

      def coerce(value, type, options={})
        return nil if value.nil?
        return value if (value.is_a?(type) rescue false)

        m = "to_#{type.to_s.downcase}"
        if Coercer.respond_to?(m) 
          Coercer.__send__(m, value, options)
        else
          nil
        end
      rescue ArgumentError
        raise InvalidParameterError, "`#{value}' is not a valid #{type}"
      end

      def validate!(value, options)
        options.each do |k, v|
          m = "check_#{k}"
          raise "unknown option `#{k}'" unless Validator.respond_to?(m)
          unless Validator.__send__(m, value, v)
            raise InvalidParameterError, Validator.message(k, v)
          end
        end
      end
    end
  end
end
