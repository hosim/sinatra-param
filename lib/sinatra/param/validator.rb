# -*- coding: utf-8 -*-

module Sinatra
  module Param
    module Validator
      class << self
        def check_required(param, option)
          ! (param.nil? and option)
        end

        def check_blank(param, option)
          return true if option
          case param
          when String
            /\S/ === param
          when Array, Hash
            ! param.empty?
          else
            ! param.nil?
          end
        end

        def check_format(param, option)
          return false unless param.kind_of? String
          param =~ option
        end

        def check_is(param, option)
          param === option
        end

        def check_range(param, option)
          return true if param.nil?
          case option
          when Range
            option.include?(param)
          else
            Array(option).include?(param)
          end
        end
        alias_method :check_in, :check_range
        alias_method :check_within, :check_range

        def check_min(param, option)
          return true if param.nil?
          option <= param
        end

        def check_max(param, option)
          return true if param.nil?
          option >= param
        end

        def check_min_length(param, option)
          return true if param.nil?
          option <= param.length
        end

        def check_max_length(param, option)
          return true if param.nil?
          option >= param.length
        end

        def message(key, value)
          ERROR_MESSAGES[key].gsub(/%{value}/, value.to_s)
        end

        ERROR_MESSAGES = {
          required: "Parameter is required",
          blank: "Parameter cannot be blank",
          format: "Parameter must match format %{value}",
          is: "Parameter must be %{value}",
          range: "Parameter must be within %{value}",
          :in => "Parameter must be within %{value}",
          within: "Parameter must be within %{value}",
          min: "Parameter cannot be less than %{value}",
          max: "Parameter cannot be greater than %{value}",
          min_length: "Parameter cannot have length less than %{value}",
          max_length: "Parameter cannot have length greater than %{value}",
        }
      end
    end
  end
end
