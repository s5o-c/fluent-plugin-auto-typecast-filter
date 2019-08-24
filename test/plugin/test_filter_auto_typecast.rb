require 'date'
require 'test/unit'

require 'fluent/log'
require 'fluent/plugin/base'
require 'fluent/plugin_id'
require 'fluent/plugin_helper'
require 'fluent/plugin/filter'
require 'fluent/test'
require 'fluent/test/helpers'
require 'fluent/test/driver/filter'


### HELPERS
module Fluent
    module Plugin
        class TestBase < Base
            include PluginId
            include PluginLoggerMixin
            include PluginHelper::Mixin
        end
    end
end

include Fluent::Test::Helpers

dl_opts = {}
dl_opts[:log_level] = ServerEngine::DaemonLogger::WARN
logdev = Fluent::Test::DummyLogDevice.new
logger = ServerEngine::DaemonLogger.new(logdev, dl_opts)
$log ||= Fluent::Log.new(logger)


### UNIT TEST
require 'fluent/plugin/filter_auto_typecast'

class AutoTypecastFilterTest < Test::Unit::TestCase
    def setup
        # Fluent::Test.setup # this is required to setup router and others
    end

    # default configuration for tests
    CONFIG = %[
    ]

    def create_driver(conf = CONFIG)
        Fluent::Test::Driver::Filter.new(Fluent::Plugin::AutoTypecastFilter).configure(conf)
    end

    def filter(config, messages)
        d = create_driver(config)
        d.run(default_tag: 'input.access') do
            messages.each do |message|
                d.feed(message)
            end
        end
        d.filtered_records
    end

    def test_input_string
        conf = CONFIG

        messages = [
            { 'k': '' },
            { 'k': 'string' },
            { 'k': 'true?' },
            { 'k': '?true' },
            { 'k': 'true1' },
            { 'k': '1true' },
            { 'k': '世界' },
            { 'k': '🐶' },
            { 'k': '世界🌏' },
            { 'k': 'null?' },
            { 'k': '?null' },
            { 'k': 'nil?' },
            { 'k': '?nil' },
        ]
        expected = [
            { 'k': '' },
            { 'k': 'string' },
            { 'k': 'true?' },
            { 'k': '?true' },
            { 'k': 'true1' },
            { 'k': '1true' },
            { 'k': '世界' },
            { 'k': '🐶' },
            { 'k': '世界🌏' },
            { 'k': 'null?' },
            { 'k': '?null' },
            { 'k': 'nil?' },
            { 'k': '?nil' },
        ]

        filtered_records = filter(conf, messages)
        assert_equal(expected, filtered_records)
    end

    def test_input_numeric
        conf = CONFIG

        messages = [
            # String
            { 'k': '0' },
            { 'k': '0.1' },
            { 'k': '1.0' },
            { 'k': '1' },
            { 'k': '1000000000000000000' },
            { 'k': '1000000000000000000.0' },
            { 'k': '1_000_000_000_000_000_000' },
            { 'k': '1_000_000_000_000_000_000.0' },
            { 'k': '1.0e+18' },

            # Object
            { 'k': 0 },
            { 'k': 0.1 },
            { 'k': 1.0 },
            { 'k': 1 },
            { 'k': 1000000000000000000 },
            { 'k': 1000000000000000000.0 },
            { 'k': 1_000_000_000_000_000_000 },
            { 'k': 1_000_000_000_000_000_000.0 },
            { 'k': 1.0e+18 },
        ]
        expected = [
            # String
            { 'k': 0 },
            { 'k': 0.1 },
            { 'k': 1.0 },
            { 'k': 1 },
            { 'k': 1.0e+18 },
            { 'k': 1.0e+18 }, # ROUNDED !
            { 'k': 1.0e+18 },
            { 'k': 1.0e+18 }, # ROUNDED !
            { 'k': 1.0e+18 },

            # Object
            { 'k': 0 },
            { 'k': 0.1 },
            { 'k': 1.0 },
            { 'k': 1 },
            { 'k': 1.0e+18 },
            { 'k': 1.0e+18 }, # ROUNDED !
            { 'k': 1.0e+18 },
            { 'k': 1.0e+18 }, # ROUNDED !
            { 'k': 1.0e+18 },
        ]

        filtered_records = filter(conf, messages)
        assert_equal(expected, filtered_records)
    end

    def test_input_boolean
        conf = CONFIG

        messages = [
            # String
            { 'k': 'true' },
            { 'k': 'TRUE' },
            { 'k': 'True' },
            { 'k': 'truE' },
            { 'k': 'false' },
            { 'k': 'FALSE' },
            { 'k': 'False' },
            { 'k': 'falsE' },

            # Object
            { 'k': true },
            { 'k': false },
        ]
        expected = [
            # String
            { 'k': true },
            { 'k': true },
            { 'k': 'True' },
            { 'k': 'truE' },
            { 'k': false },
            { 'k': false },
            { 'k': 'False' },
            { 'k': 'falsE' },

            # Object
            { 'k': true },
            { 'k': false },
        ]

        filtered_records = filter(conf, messages)
        assert_equal(expected, filtered_records)
    end

    def test_input_nil
        conf = CONFIG

        messages = [
            # String
            { 'k': 'null' },
            { 'k': 'NULL' },
            { 'k': 'Null' },
            { 'k': 'nulL' },
            { 'k': 'nil' },
            { 'k': 'NIL' },
            { 'k': 'Nil' },
            { 'k': 'niL' },

            # Object
            { 'k': nil },
        ]
        expected = [
            # String
            { 'k': nil },
            { 'k': nil },
            { 'k': 'Null' },
            { 'k': 'nulL' },
            { 'k': nil },
            { 'k': nil },
            { 'k': 'Nil' },
            { 'k': 'niL' },

            # Object
            { 'k': nil },
        ]

        filtered_records = filter(conf, messages)
        assert_equal(expected, filtered_records)
    end

    def test_input_array
        conf = CONFIG

        messages = [
            # Object
            { 'k': [ 'v', { 'k': 'v' }, 0, 0.1, 1.0, 1, true, false, nil ] },
        ]
        expected = [
            # Object
            { 'k': [ 'v', { 'k': 'v' }, 0, 0.1, 1.0, 1, true, false, nil ] },
        ]

        filtered_records = filter(conf, messages)
        assert_equal(expected, filtered_records)
    end

    def test_input_hash
        conf = CONFIG

        messages = [
            # Object
            { 'k': { 'k': 'v' } },
        ]
        expected = [
            # Object
            { 'k': { 'k': 'v' } },
        ]

        filtered_records = filter(conf, messages)
        assert_equal(expected, filtered_records)
    end

    def test_input_object
        conf = CONFIG

        x = DateTime.now

        messages = [
            # Object
            { 'k': x },
        ]
        expected = [
            # Object
            { 'k': x },
        ]

        filtered_records = filter(conf, messages)
        assert_equal(expected, filtered_records)
    end

    def test_input_numeric_in_array
        conf = CONFIG

        messages = [
            # Object
            { 'k': [ '0', '0.1', '1.0', '1', [ '0', '0.1', '1.0', '1' ] ] },
        ]
        expected = [
            # Object
            { 'k': [ '0', '0.1', '1.0', '1', [ '0', '0.1', '1.0', '1' ] ] },
        ]

        filtered_records = filter(conf, messages)
        assert_equal(expected, filtered_records)
    end

    def test_input_numeric_in_array_maxdepth_3
        conf = CONFIG + %[
            maxdepth 3
        ]

        messages = [
            # Object
            { 'k': [ [ '0', '0.1', '1.0', '1' ] ] },
        ]
        expected = [
            # Object
            { 'k': [ [ 0, 0.1, 1.0, 1 ] ] },
        ]

        filtered_records = filter(conf, messages)
        assert_equal(expected, filtered_records)
    end

    def test_input_numeric_in_array_disabled_maxdepth
        conf = CONFIG + %[
            maxdepth 0
        ]

        messages = [
            # Object
            { 'k': [ [ [ [ '0', '0.1', '1.0', '1' ] ] ], [ '0', '0.1' ] ] },
        ]
        expected = [
            # Object
            { 'k': [ [ [ [ 0, 0.1, 1.0, 1 ] ] ], [ 0, 0.1 ] ] },
        ]

        filtered_records = filter(conf, messages)
        assert_equal(expected, filtered_records)
    end

    def test_input_numeric_in_hash
        conf = CONFIG

        messages = [
            # Object
            { 'k': [ '0', '0.1', '1.0', '1', { 'k1': [ '0', '0.1', '1.0', '1' ], 'k2': '1.0' } ] },
        ]
        expected = [
            # Object
            { 'k': [ '0', '0.1', '1.0', '1', { 'k1': [ '0', '0.1', '1.0', '1' ], 'k2': '1.0' } ] },
        ]

        filtered_records = filter(conf, messages)
        assert_equal(expected, filtered_records)
    end

    def test_input_numeric_in_hash_maxdepth_3
        conf = CONFIG + %[
            maxdepth 3
        ]

        messages = [
            # Object
            { 'k': { 'k': { 'k': '0.0' } } },
        ]
        expected = [
            # Object
            { 'k': { 'k': { 'k': 0.0 } } },
        ]

        filtered_records = filter(conf, messages)
        assert_equal(expected, filtered_records)
    end

    def test_input_numeric_in_hath_disabled_maxdepth
        conf = CONFIG + %[
            maxdepth 0
        ]

        messages = [
            # Object
            { 'k': { 'k1': { 'k': { 'k': { 'k': '0.1' } } }, 'k2': { 'k': '1.0' } } }
        ]
        expected = [
            # Object
            { 'k': { 'k1': { 'k': { 'k': { 'k': 0.1 } } }, 'k2': { 'k': 1.0 } } }
        ]

        filtered_records = filter(conf, messages)
        assert_equal(expected, filtered_records)
    end

    def test_input_numeric_in_array_hash
        conf = CONFIG + %[
            maxdepth 0
        ]

        messages = [
            # Object
            { 'k': { 'k': { 'k': [ { 'k': { 'k1': '0', 'k2': '0.1', 'k3': '1.0', 'k4': '1' } } ] } } }
        ]
        expected = [
            # Object
            { 'k': { 'k': { 'k': [ { 'k': { 'k1': 0, 'k2': 0.1, 'k3': 1.0, 'k4': 1 } } ] } } }
        ]

        filtered_records = filter(conf, messages)
        assert_equal(expected, filtered_records)
    end
end
