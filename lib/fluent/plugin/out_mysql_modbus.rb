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
  end

  def configure(conf)
    super
    @modbus_id_cache = Hash.new
    @init = {
      :host => @dbhost,
      :port => @dbport,
      :username => @username,
      :password => @password,
      :database => @database
    }
    sql = "CREATE TABLE IF NOT EXISTS #{@database}.sensors("\
        "sensor_id INTEGER NOT NULL AUTO_INCREMENT,"\
        "sensor_name VARCHAR(32) NOT NULL,"\
        "host VARCHAR(32) NOT NULL,"\
        "reg_addr INTEGER NOT NULL,"\
        "unit VARCHAR(32),"\
        "PRIMARY KEY(sensor_id) )"
    handler = Mysql2::Client.new(@init)
    handler.query(sql)
    handler.close    
  end

  def format(tag, time, record)
    return [tag, time, record].to_msgpack
  end

  def start
    super
  end

  def shutdown
    super
  end
  
  def write(chunk)
    handler = Mysql2::Client.new(@init)

    chunk.msgpack_each do |tag, time, record|
      @raw_value = record["raw_value"]
      @host = record["host"]
      @reg_addr = record["reg_addr"]
      @sensor_name = record["sensor_name"]

      sensor_id = @modbus_id_cache["#{@host}.#{@sensor_name}"]
      if sensor_id.nil?
        sensor_id = get_sensor_id(handler)
        @modbus_id_cache["#{@host}.#{@sensor_name}"] = sensor_id
      end
      
      value, percentile = convert(@raw_value) 
      month_table = get_month_table(handler, time)
      sql = "INSERT INTO #{month_table} (sensor_id, time, raw_value, value, percentile)"\
      "VALUES (#{sensor_id}, '#{Time.at(time).to_s}', #{@raw_value}, #{value}, #{percentile})"
      p sql
      handler.query(sql)
    end

    handler.close
  end

  def get_sensor_id(handler)
    sql = "SELECT sensor_id FROM #{@database}.sensors WHERE sensor_name='#{@sensor_name}'"
    result = handler.query(sql).each do |sensor_id|
      sensor_id.each do |key, val|
        return val
      end
    end
    if result.empty?
      sql = "INSERT INTO #{@database}.sensors (sensor_name, host, reg_addr, unit) VALUES ('#{@sensor_name}', '#{@host}', #{@reg_addr}, '#{@unit}')"
      p sql
      result = handler.query(sql)
      get_sensor_id(handler)
    end
  end

  def get_month_table(handler, time)
    # TODO: Valid date confirmation is needed
    table_name = "data_" + Time.at(time).strftime("%Y%m")
    sql = "SHOW TABLES LIKE '#{table_name}'"
    result = handler.query(sql).each do |table|
      unless table.empty?
        return table_name
      end
    end
    sql = "CREATE TABLE IF NOT EXISTS #{@database}.#{table_name} ("\
    "id INTEGER NOT NULL AUTO_INCREMENT,"\
    "sensor_id INTEGER NOT NULL,"\
    "time DATETIME NOT NULL,"\
    "raw_value FLOAT NOT NULL,"\
    "value FLOAT,"\
    "percentile FLOAT,"\
    "PRIMARY KEY(id) )"
    p sql
    handler.query(sql)
    get_month_table(handler, time)
  end

  def convert(raw)
    # Convert the value in the device's unit
    val = (@max_sensor_output / @max_modbus_input) * raw 
    perc = val/@max_sensor_output*100.0
    return val, perc
  end
end
