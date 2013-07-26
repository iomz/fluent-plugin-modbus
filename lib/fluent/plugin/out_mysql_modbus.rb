class Fluent::MysqlModbusOutput < Fluent::BufferedOutput
  Fluent::Plugin.register_output('mysql_modbus', self)

  config_param :dbhost, :string
  config_param :dbport, :integer, :default => nil
  config_param :database, :string
  config_param :username, :string
  config_param :password, :string, :default => ''

  config_param :max_modbus_input, :float         # Max value of input
  config_param :max_sensor_output, :float        # Max value of device output
  config_param :unit, :string, :defalut => nil   # Unit for device output
 
  attr_accessor :handler

  def initialize
    super
    require 'mysql2-cs-bind'
    @modbus_id_cache = Hash.new
  end

  def configure(conf)
    super
  end

  def start
    super
  end

  def shutdown
    super
  end
  
  def write(chunk)
    init = {
      :host => @dbhost,
      :port => @dbport,
      :username => @username,
      :password => @password,
      :database => @database
    }

    handler = Mysql2::Client.new(init)

    chunk.msgpack_each do |sensor_name,time,record|
      sensor_id = @modbus_id_cache["#{record["host"]}.#{sensor_name}"]
      if sensor_id.nil?
        sensor_id = get_sensor_id(handler, record, @unit)
        @modbus_id_cache["#{record["host"]}.#{sensor_name}"] = sensor_id
      end
      
      raw_value = record["raw"]
      value, percentile = convert(raw_value) 
      month_table = get_month_table(handler)
      sql = "INSERT INTO #{month_table} (sensor_id, time, raw_value, value, percentile) VALUES (#{sensor_id}, #{time}, #{raw_value}, #{value}, #{percentile})"
      p sql
      handler.query(sql)
    end

    handler.close
  end

  private

  def get_sensor_id(handler, record, unit)
    sql = "SELECT sensor_id FROM modbus.sensors WHERE sensor_name='#{sensor_name}'"
    result = handler.query(sql).each do |sensor_id|
      sensor_id.each do |key, val|
        return val
      end
    end
    if result.empty?
      sql = "INSERT INTO modbus.sensors (sensor_name, host, port, unit) VALUES ('#{sensor_name}', '#{record["host"]}', '#{record["port"]}', '#{unit}')"
      result = handler.query(sql)
      get_sensor_id(handler, record, unit)
    end
  end

  def get_month_table(handler)
    # TODO: Valid date confirmation is needed
    table_name = "data_" + Time.at(time).strftime("%Y%m")
    sql = "SHOW TABLES LIKE '#{table_name}'"
    result = handler.query(sql).each do |table|
      unless table.empty?
        return table_name
      end
    end
    sql = "CREATE TABLE '#{table_name}' (
        id integer not null auto_increment primary key,
        sensor_id integer,
        time integer not null,
        raw_value float,
        value float,
        percentile float,
    )"
    handler.query(sql)
    get_month_table(handler)
  end

  def convert(raw)
    # Convert the value in the device's unit
    val = (@max_sensor_output / @max_modbus_input) * raw 
    perc = val/@max_sensor_output*100.0
    return val, perc
  end
end
