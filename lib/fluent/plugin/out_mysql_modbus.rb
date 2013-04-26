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
        modbus_id = @modbus_id_cache["#{data["host_name"]}.#{data["modbus_name"]}"]
        if modbus_id.nil?
          modbus_id = get_modbus_id(handler,data["host_name"],data["modbus_name"])
          @modbus_id_cache["#{data["host_name"]}.#{data["modbus_name"]}"] = modbus_id
        end
        raw = data["raw"]
        value = fake_translate(data["raw"].to_i) # require translate function
        month_table = "data_" + Time.at(time).strftime("%Y%m")
        sql = "INSERT INTO #{month_table} (time, raw, value, modbus_id) VALUES (#{time}, #{raw}, #{value}, #{modbus_id})"
        p sql
        handler.query(sql)
      end

      handler.close
    end

    private

    def fake_translate(rawdata)
      return rawdata.to_i * 0.2
    end

    #def get_modbus_id(handler,host_name,modbusDevice)
    def get_modbus_id(handler,host_name,modbus_name)
      #sql = "SELECT modbus_id FROM modbus JOIN host ON modbus.host_id=host.host_id WHERE host.host_name='#{host_name}' AND modbus_name='#{modbusDevice}'" 
      sql = "SELECT modbus_id FROM modbus JOIN host ON modbus.host_id=host.host_id WHERE host.host_name='#{host_name}' AND modbus_name='#{modbus_name}'"
      result = handler.query(sql).each do |modbus_id|
        modbus_id.each do |key, val|
          return val
        end
      end
      if result.empty?
        set_host_id(handler, host_name)
        host_id = get_host_id(handler,host_name)
        #set_modbus(handler, modbus_name, "NULL", host_id)
        set_modbus(handler, modbus_name, host_id)
        get_modbus_id(handler, host_name, modbus_name)
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

    #def set_modbus(handler,modbus_name,place_id,host_id)
    def set_modbus(handler,modbus_name,host_id)
      #sql = "INSERT INTO modbus (modbus_name, place_id, host_id) VALUES ('#{modbus_name}', #{place_id}, #{host_id})"
      sql = "INSERT INTO modbus (modbus_name, host_id) VALUES ('#{modbus_name}',#{host_id})"
      p sql
      handler.query(sql)
    end

  end
end
