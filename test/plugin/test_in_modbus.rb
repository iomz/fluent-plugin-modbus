require '../helper'
require 'in_modbus'
require 'time'

class ModbusInputTest < Test::Unit::TestCase

  def setup
    Fluent::Test.setup
    @obj = Fluent::ModbusInput.new
  end

  CONFIG = %[
    tag modbus.test1
    hostname 192.168.0.37 
    port 502
    polling_time 0,30
    modbus_retry 1
    reg_size 16
    reg_addr 0
    nregs 1
    max_input 10000
    max_device_output 2000
    unit W/m^2
    data_format %.2f %%, %.1f %s
    format_type 3
  ]
  
  def create_driver(conf=CONFIG)
    Fluent::Test::InputTestDriver.new(Fluent::ModbusInput).configure(conf)
  end

  def test_configure
    d = create_driver

    # Params
    assert_equal 'modbus.test1', d.instance.tag
    assert_equal '192.168.0.37', d.instance.hostname
    assert_equal 502, d.instance.port
    assert_equal [0,30], d.instance.polling_time
    assert_equal 1, d.instance.modbus_retry
    assert_equal 16, d.instance.reg_size
    assert_equal 0, d.instance.reg_addr
    assert_equal 1, d.instance.nregs
    assert_equal 10000.0, d.instance.max_input
    assert_equal 2000.0, d.instance.max_device_output
    assert_equal 'W/m^2', d.instance.unit
    assert_equal '%.2f %%, %.1f %s', d.instance.data_format
    assert_equal 3, d.instance.format_type
  end

  def test_modbus_tcp_client
    d = create_driver
    hostname = d.instance.hostname
    port = d.instance.port
    tag = d.instance.tag
    reg_addr = d.instance.reg_addr
    nregs = d.instance.nregs
    modbus_retry = d.instance.modbus_retry
    
    ModBus::TCPClient.new(hostname, port) do |cl|
      cl.with_slave(modbus_retry) do |sl|
        @reg = sl.read_input_registers(reg_addr, nregs)
      end
    end

    assert_equal Array, @reg
  end

  def test_translate_reg
    d = create_driver
    reg_size = d.instance.reg_size

    nregs = 2 
    reg = [0b1011111110000000, 0b0000000000000000] # 2 16 bit registers, float -1.0 in binay
    raw = @obj.__send__(:translate_reg, reg, nregs, reg_size)
    assert_equal -1.0, raw

    nregs = 1
    reg = [0b1111111111111111]
    raw = @obj.__send__(:translate_reg, reg, nregs, reg_size)
    assert_equal -1, raw
  end

  def test_data_emission
    d = create_driver
    nregs = d.instance.nregs
    reg_size = d.instance.reg_size
    max_device_output = d.instance.max_device_output
    max_input = d.instance.max_input
    format_type = d.instance.format_type
    data_format = d.instance.data_format
    unit = d.instance.unit
    tag = d.instance.tag
    
    nregs = 2
    reg = [0b1011111110000000, 0b0000000000000000] # 2 16 bit registers, float -1.0 in binay
    data = @obj.__send__(:modbus_fetch_data, reg, nregs, reg_size, max_device_output, max_input, format_type, data_format, unit, tag, true)

    assert_equal Float, data[:raw]
    assert_equal String, data[:record]

    nregs = 1
    reg = [0b1111111111111111]
    data = @obj.__send__(:modbus_fetch_data, reg, nregs, reg_size, max_device_output, max_input, format_type, data_format, unit, tag, true)

    assert_equal Integer, data[:raw]
    assert_equal String, data[:record]

  end
      

end
