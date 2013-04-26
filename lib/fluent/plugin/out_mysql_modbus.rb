require "#{File.dirname(__FILE__)}/out_mysql"
module Fluent
  class MysqlModbusOutput < MysqlOutput
    Plugin.register_output('mysql_modbus', self)

    config_param :raw_data_type, :string, :default => "integer" # Raw data type [integer|float]
    config_param :max_input, :float         # Max value of input
    config_param :max_device_output, :float # Max value of device output
    config_param :unit, :string, :defalut => nil # Unit for device output
    
    def initialize
      super
      @modbus_id_cache = Hash.new
    end

    def format(tag, time, record)
      return [tag, time, record].to_msgpack
    end

    def write(chunk)
      init = {
        :host => @host,
        :port => @port,
        :username => @username,
        :password => @password,
        :database => @database
      }

      handler = Mysql2::Client.new(init)

      chunk.msgpack_each do |tag,time,data|
        modbus_id = @modbus_id_cache["#{data["host"]}.#{data["sensor_name"]}"]
        if modbus_id.nil?
          modbus_id = get_modbus_id(handler,data["host"],data["sensor_name"],@unit)
          @modbus_id_cache["#{data["host"]}.#{data["sensor_name"]}"] = modbus_id
        end

        raw = @raw_data_type=="integer" ? data["raw"].to_i : data["raw"].to_f
        value, percentile = convert(raw) 
        month_table = "data_" + Time.at(time).strftime("%Y%m")
        sql = "INSERT INTO #{month_table} (time, raw, value, percentile, modbus_id) VALUES (#{time}, #{raw}, #{value}, #{percentile}, #{modbus_id})"
        p sql
        handler.query(sql)
      end

      handler.close
    end

    private

    def convert(raw)
      # Convert the value in the device's unit
      val = (@max_device_output / @max_input) * raw 
      perc = val/@max_device_output*100.0
      return val, perc
    end

    def get_modbus_id(handler,host_name,sensor_name,unit)
      sql = "SELECT modbus_id FROM modbus JOIN host ON modbus.host_id=host.host_id WHERE host.host_name='#{host_name}' AND sensor_name='#{sensor_name}'"
      result = handler.query(sql).each do |modbus_id|
        modbus_id.each do |key, val|
          return val
        end
      end
      if result.empty?
        set_host_id(handler, host_name)
        host_id = get_host_id(handler,host_name)
        set_modbus(handler, sensor_name, host_id, unit)
        get_modbus_id(handler, host_name, sensor_name)
      end
    end

    def get_host_id(handler,host_name)
      sql = "SELECT host_id FROM host WHERE host_name='#{host_name}'"
      result = handler.query(sql).each do |host_id|
        host_id.each do |key, val|
          return val
        end
      end
    end

    def set_host_id(handler, host_name)
      sql = "SELECT host_name from host where host_name='#{host_name}'"
      result = handler.query(sql).each do |host_id|
      end
      if result.empty?
        sql = "INSERT INTO host (host_name) VALUES ('#{host_name}')"
        result = handler.query(sql)
      end
    end

    def set_modbus(handler,sensor_name,host_id,unit)
      sql = "INSERT INTO modbus (sensor_name, host_id, unit) VALUES ('#{sensor_name}',#{host_id},'#{unit}')"
      p sql
      handler.query(sql)
    end

  end
end
