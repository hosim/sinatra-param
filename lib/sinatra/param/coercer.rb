# -*- coding: utf-8 -*-

module Sinatra
  module Param
    module Coercer
      class << self
        def to_array(value, options)
          return value if value.is_a?(Array)
          delimiter = options[:delimiter] || ','
          Array(value.split(delimiter))
        end

        def to_hash(value, options)
          return value if value.is_a?(Hash)
          delimiter = options[:delimiter] || ','
          separator = options[:separator] || ':'
          Hash[value.split(delimiter).map {|c|
                 c.split(separator)
               }]
        end

        def to_boolean(value, options)
          if /(false|f|no|n|0)$/i === value.to_s
            false
          elsif /(true|t|yes|y|1)$/i === value.to_s
            true
          else
            nil
          end
        end

        [Integer, Float, String, Date, Time, DateTime].each do |t|
          define_method "to_#{t.to_s.downcase}",
            if t.respond_to?(:parse)
              ->(value, options) { t.parse(value) }
            else
              ->(value, options) { __send__ t.to_s, value }
            end
        end
      end
    end
  end
end
