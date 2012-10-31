require "#{File.dirname(__FILE__)}/in_modbus"

module Fluent
  class ModbusCHFInput < ModbusInput
    Plugin.register_input('modbus_CHF-LP02-4', self)

    def modbus_aggregate_data(modbus_tcp_client, test = false)
      val = modbus_tcp_client.with_slave(1).read_input_registers(0, 8)
      record = to_signed(val[0], 16) # Convert 16bit unsigned integer to signed
      record = convert_unit(record, 10000, 2000) # Convert value of 0-10k to 0-2kW 
      time = Engine.now
      Engine.emit(@tag, time, record, unit)
      return {:time => time, :record => record} if test
    end

    def to_signed(value, bits)
      mask = (1 << (bits - 1))
      return (value & ~mask) - (value &mask)
    end

    def convert_unit(value, origin_max, new_max)
      return (value / origin_max) * new_max
    end
end
