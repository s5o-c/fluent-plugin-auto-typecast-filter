require 'fluent/plugin/filter'

class String
    def numeric?
        Float(self) != nil rescue false
    end

    def boolean?
        return true if self =~ /^(?:true|false|TRUE|FALSE)$/

        false
    end

    def nil?
        return true if self =~ /^(?:null|nil|NULL|NIL)$/

        false
    end

    def to_numeric!
        if self.numeric?
            if self.index('.')
                return self.to_f
            else
                return self.to_i
            end
        end

        0
    end

    def to_boolean!
        return true  if self =~ /^(?:true|TRUE)$/i
        return false if self =~ /^(?:false|FALSE)$/i

        false
    end

    def to_nil!
        nil
    end
end

module Fluent::Plugin
    class AutoTypecastFilter < Filter
        Fluent::Plugin.register_filter('auto_typecast', self)

        config_param :deep_dive, :bool, default: false

        # def configure(conf)
        #     super
        #     # do the usual configuration here
        # end

        # def start
        #     super
        #     # Override this method if anything needed as startup.
        # end

        # def shutdown
        #     # Override this method to use it to free up resources, etc.
        #     super
        # end

        private def transform(x, k, v)
            y = String("#{v}")

            x[k] = y.to_numeric! if y.numeric?

            x[k] = y.to_boolean! if y.boolean?

            x[k] = y.to_nil! if y.nil?

            auto_typecast(v) if @deep_dive
        end

        private def auto_typecast(x)
            return x if ! x.kind_of?(Enumerable)

            x.each do |k, v|
                transform(x, k, v)
            end if x.kind_of?(Hash)

            x.each_with_index do |v, k|
                transform(x, k, v)
            end if x.kind_of?(Array)
        end

        def filter(tag, time, record)
            auto_typecast(record)

            record
        end
    end
end
