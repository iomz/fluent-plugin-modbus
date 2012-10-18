#require 'test/unit'
#require 'fluent/test'
#require 'lib/fluent/plugin/in_modbus'
#require 'time'
require 'helper'

class ModbusInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
    @obj = Fluent::ModbusInput.new
  end

  CONFIG = %[
    tag monbus.server1
    polling_time 0,10,20,30,40,50
    hostname 192.168.0.37 
    port 502
  ]
  
  def create_driver(conf=CONFIG)
    Fluent::Test::InputTestDriver.new(Fluent::ModbusInput).configure(conf)
  end

  def test_configure
    d = create_driver

    # Fluent Params
    assert_equal 'modbus.server1', d.instance.tag
    assert_equal [0,10,20,30,40,50], d.instance.pollint_time

    # Modbus Params
    assert_equal "localhost", d.instance.hostname
    assert_equal 502, d.instance.port
  end

  def test_sleep_interval
    Time.stubs(:now).returns(Time.parse "2012/12/31 23:59:59")
    assert_equal 1, @obj.__send__(:sleep_interval,60)

    Time.stubs(:now).returns(Time.parse "2012/12/31 23:59:50")
    assert_equal false, @obj.__send__(:sleep_interval,10)

    Time.stubs(:now).returns(Time.parse "2012/12/31 23:59:59")
    assert_equal 1, @obj.__send__(:sleep_interval,0,false)

    Time.stubs(:now).returns(Time.parse "2012/12/31 23:59:50")
    assert_equal false, @obj.__send__(:sleep_interval,50,false)

    # Test OK
    #Time.stubs(:now).returns(Time.parse "2012/12/31 23:59:50")
    #assert_equal 70, @obj.__send__(:sleep_interval,120,0)
  end

  def test_modbus_aggregate_data
    d = create_driver
    hostname = d.instance.hostname
    port = d.instance.port
    tag = d.instance.tag
    
    # unixtime 1356965990
    Time.stubs(:now).returns(Time.parse "2012/12/31 23:59:50")
    modbus_tcp_client = ModBus::TCPClient.new(@hostname, @port)
    
    data = @obj.__send__(:modbus_aggregate_data, modbus_tcp_client, true)

    assert_equal 1356965990, data[:time]
    assert_equal Integer, data[:record]
  end

end
