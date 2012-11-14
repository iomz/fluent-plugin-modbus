require 'rmodbus'

module Fluent
  class ModbusInput < Input
    Plugin.register_input('modbus', self)

    # Fluent Params
    # require param: tag, hostname, port
    config_param :tag, :string
    config_param :hostname, :string
    config_param :port, :integer
    config_param :polling_time, :string, :default => nil # Seconds separated by ','
    config_param :modbus_retry, :integer, :default => 1 # Retry count for connecting to modbus device 
    config_param :reg_size, :integer, :default => 16 # Bit size of one register
    config_param :reg_addr, :integer, :default => 0  # Address of the first registers
    config_param :nregs, :integer, :default => 1     # Number of registers
    config_param :max_input, :float                  # Max value of input
    config_param :max_device_output, :float          # Max value of device output
    config_param :unit, :string, :defalut => nil     # Unit for device output
    config_param :data_format, :string, :default =>"%d" # String format for data
    config_param :format_type, :integer, :default => 0  # Specify the elements to intepret by data_format 

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
        # Get an array of registers
        mtc do |cl|
          cl.with_slave(@modbus_retry) do |sl|
            reg = sl.read_input_registers(@reg_addr, @nregs)
          end
        end
        modbus_fetch_data(reg)
      end
    rescue => exc
      p exc
      $log.error "run failed", :error=>ex.message
      sleep(10)
      retry
    end

    # Called on Ctrl-c
    def shutdown
      @modbus_tcp_client.close
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
    
    def translate_reg(reg, nregs, reg_size)
      if nregs==1 && reg_size==16         # 16bit integer
        return reg.pack("S").unpack("s")[0]
      elsif nregs==2 && reg_size==16      # 32bit float, big-endian
        return reg.pack("nn").unpack("g")[0]
      else 
        return reg[0]
      end
    end

    def modbus_fetch_data(reg, test = false)
      
      # Translate the register array to the value
      raw = translate_reg(reg, @nregs, @reg_size)
      
      # Convert the value in the device's unit
      val = (@max_device_output / @max_input) * raw 
      percentile = val/@max_device_output*100.0

      case @format_type  # [raw, percentile, val] express which to display as 3 bits
      when 1 
          record = @data_format % [val,@unit]
      when 2
          record = @data_format % [percentile]
      when 3
          record = @data_format % [percentile, val, @unit]
      else
          record = @data_format % [raw]
      end

      time = Engine.now
      Engine.emit(@tag, time, record)
      return {:reg => reg, :record => record} if test
    end

  end
end
