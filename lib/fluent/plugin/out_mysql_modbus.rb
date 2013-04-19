#require '/var/service/asama/local/lib/ruby/gems/1.9.1/gems/fluent-plugin-mysql-0.0.2/lib/fluent/plugin/out_mysql'
require 'out_mysql'
module Fluent
  class MysqlModbusOutput < MysqlOutput
    Plugin.register_output('mysql_modbus', self)
    
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

        modbus_id = @modbus_id_cache["#{data["host_name"]}.#{data["modbusDevice"]}"]
        if modbus_id.nil?
          modbus_id = get_modbus_id(handler,data["host_name"],data["modbusDevice"])
          @modbus_id_cache["#{data["host_name"]}.#{data["modbusDevice"]}"] = modbus_id
        end

        temp, humidity = data["modbusValue_degC"], data["modbusValue_%RH"]
        month_table = "data_" + Time.at(time).strftime("%Y%m")
        sql = "INSERT INTO #{month_table} (modbus_id,time,temp,humidity) VALUES (#{modbus_id},#{time},#{temp},#{humidity})"
        handler.query(sql)
      end

      handler.close
    end

    private

    def get_modbus_id(handler,host_name,modbusDevice)
      sql = "SELECT modbus_id FROM modbus JOIN host ON modbus.host_id=host.host_id WHERE host.host_name='#{host_name}' AND modbus_name='#{modbusDevice}'" 
      result = handler.query(sql).each do |modbus_id|
        modbus_id.each do |key, val|
          return val
        end
      end
      if result.empty?
        host_id = get_host_id(handler,host_name)
        set_modbus(handler, modbusDevice, "NULL", host_id)
        get_modbus_id(handler, host_name, modbusDevice)
      end
    end

    def get_host_id(handler,host_name)
      sql = "SELECT host_id FROM host WHERE host_name='#{host_name}'"
      handler.query(sql).each do |host_id|
        host_id.each do |key, val|
          return val
        end
      end
    end

    def set_modbus(handler,modbus_name,place_id,host_id)
      sql = "INSERT INTO modbus (modbus_name, place_id, host_id) VALUES ('#{modbus_name}', #{place_id}, #{host_id})"
      handler.query(sql)
    end

  end
end
