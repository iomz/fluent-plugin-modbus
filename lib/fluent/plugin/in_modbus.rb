require 'rmodbus'

module Fluent
  class ModbusInput < Input
    Plugin.register_input('modbus', self)

    # Fluent Params
    # require param: tag, mib
    config_param :tag, :string
    config_param :hostname, :string
    config_param :port, :integer
    config_param :polling_time, :string, :default => nil # Seconds separated by ',' 
    config_param :reg_size, :integer, :default => 16 # Bit size of one register
    config_param :reg_addr, :integer, :default => 0 # Address of the first registers
    config_param :nregs, :integer, :default => 1 # Number of registers
    config_param :max_input, :float, :default => nil # Max value of input
    config_param :max_device_output, :float, :defaut => nil # Max value of device output
    config_param :unit, :string, :defalut => nil # Unit for device output
    config_param :data_format, :string, :default =>"%d %s" # String format for data

    def initialize
      super
    end  

    def configure(conf)                                                         
      super

      # Parse polling_time to list
      @polling_time = @polling_time.split(',').map{|str| str.strip.to_i} unless @polling_time.nil?
      raise ConfigError, "modbus: 'polling_time' parameter is required on modbus input" if !@polling_time.nil? && @polling_time.empty?
    end

    def starter
      @starter = Thread.new do
        sleep_interval(60)
        yield
      end
    end

    def start
      starter do
        begin
            @modbus_tcp_client = ModBus::TCPClient.new(@hostname, @port)
        rescue => exc
            p exc
            shutdown
        end
        @thread = Thread.new(&method(:run))
        @end_flag = false
      end
    end

    def run
      watcher do
        modbus_aggregate_data(@modbus_tcp_client)
      end
    rescue => exc
      p exc
      $log.error "run failed", :error=>ex.message
      sleep(10)
      retry
    end

    # Called on Ctrl-c
    def shutdown
      @end_flag = true
      @thread.run
      @thread.join
      @starter.join
    end

    private

    def sleep_interval(interval,zero_start = true)
      now_to_f = Time.now.to_f
      secs = interval - (now_to_f % 60)
      if zero_start != true && secs < 0
        secs = 60 - secs.abs
      end
      secs > 0 ? (sleep secs) : false
    end

    def watcher
      zero_start = true
      loop do
        # [0,30].each do |time|
        @polling_time.each do |time|
          break if @end_flag
          sleep_interval(time, zero_start)
          zero_start = false
          yield
        end
        break if @end_flag
      end
    end
    
    def translate_reg(reg)
      if @nregs==1 && @reg_size==16         # 16bit integer
        return reg.pack("S").unpack("s")[0]
      elsif @nregs==2 && @reg_size==16      # 32bit float, big-endian
        return reg.pack("nn").unpack("g")[0]
      else 
        return reg[0]
      end
    end

    def modbus_aggregate_data(modbus_tcp_client, test = false)
      # Get an array of register
      reg = modbus_tcp_client.with_slave(1).read_input_registers(@reg_addr, @nregs)
      
      # Translate the register array to the value
      val = translate_reg(reg)
      
      # Convert the value in the device's unit
      val = (@max_device_output / @max_input) * val

      record = @data_format%[val,@unit]

      time = Engine.now
      Engine.emit(@tag, time, record)
      return {:time => time, :record => record} if test
    end

  end
end
