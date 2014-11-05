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
        return unless block_given? and value.respond_to?(:[])

        (value.is_a?(Array) ? value : [value]).each do |v|
          @requester.instance_eval {
            @__sinatra_param = Core.new(self, v)
            instance_eval(&block)
            remove_instance_variable(:@__sinatra_param) if @__sinatra_param
          }
        end
      end

      private
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
        Coercer.respond_to?(m) ? Coercer.__send__(m, value, options) : nil
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

      def method_missing(name, *args, &block)
        return super unless @requester.respond_to?(name, true)
        @requester.__send__ name, *args, &block
      end
    end
  end
end
