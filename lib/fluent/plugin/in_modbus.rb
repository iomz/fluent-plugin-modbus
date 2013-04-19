module Fluent
    
class ModbusInput < Input
    Plugin.register_input('modbus', self)

    # Fluent Params
    # require param: tag, hostname
    config_param :tag, :string
    config_param :hostname, :string
    config_param :port, :integer, :default => 502       # Port used by modbus
    config_param :polling_time, :string, :default => "0,30" # Seconds separated by ','
    config_param :modbus_retry, :integer, :default => 1 # Retry count for connecting to modbus device 
    config_param :reg_size, :integer, :default => 16    # Bit size of one register
    config_param :reg_addr, :integer, :default => 0     # Address of the first registers
    config_param :nregs, :integer, :default => 1        # Number of registers

    def initialize
      super
      require 'rmodbus'
    end  

    def configure(conf)                                                         
      super

      raise ConfigError, "tag is required param" if @tag.empty?
      raise ConfigError, "hostname is required param" if @hostname.empty?

      # Parse polling_time to list
      @polling_time = @polling_time.split(',').map{|str| str.strip.to_i} unless @polling_time.nil?
      raise ConfigError, "modbus: 'polling_time' parameter is required on modbus input" if @polling_time.empty?
    end

    # Wait until the next zero second
    def starter
      @starter = Thread.new do
        sleep_interval(60)
        yield   # starter proc in :start 
      end
    end

    def start
      starter do
        begin
            mtc = ModBus::TCPClient.new(@hostname, @port)
        rescue => ex
            p ex
            shutdown # If connection failed, shutdown
        end
        mtc.close unless mtc.closed?
        @thread = Thread.new(&method(:run))
        @end_flag = false
      end
    end

    def run
      watcher do
        # Get an array of registers
        ModBus::TCPClient.new(@hostname, @port) do |cl|
          cl.with_slave(@modbus_retry) do |sl|
            @reg = sl.read_input_registers(@reg_addr, @nregs)
          end
        end
        modbus_fetch_data
      end
    rescue => ex
      $log.error "modbus failed to fetch data ", :error=>ex.message
      sleep(10)
      retry
    end

    # Call sleep_interval according to the polling time
    def watcher
      zero_start = true
      loop do
        @polling_time.each do |time|
          break if @end_flag
          sleep_interval(time, zero_start)
          zero_start = false
          yield
        end
        break if @end_flag
      end
    end
    
     # Called on Ctrl-c
    def shutdown
      @end_flag = true
      @thread.run
      @thread.join
      @starter.join
      @modbus_tcp_client.close
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

    # Translation and check data type from the register
    def translate_reg(reg, nregs, reg_size)
      if nregs==1 && reg_size==16         # 16bit integer
        return reg.pack("S").unpack("s")[0]
      elsif nregs==2 && reg_size==16      # 32bit float, big-endian
        return reg.pack("nn").unpack("g")[0]
      else 
        return reg[0]
      end
    rescue => ex
        $log.error "modbus failed to check_type", :error =>ex.message
        $log.warn_backtrace ex.backtrace
    end
      
    def modbus_fetch_data(test = false)
      # Translate the register array to the value
      raw = translate_reg(@reg, @nregs, @reg_size)

=begin
      # Convert the value in the device's unit
      val = (@max_device_output / @max_input) * raw 
      percentile = val/@max_device_output*100.0
=end

      record = "#{raw}"

      time = Engine.now
      Engine.emit(@tag, time, record)
      return {:raw => raw, :record => record} if test
    end

  end
end
