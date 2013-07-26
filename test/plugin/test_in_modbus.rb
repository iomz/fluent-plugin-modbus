s

  def test_modbus_tcp_client
    d = create_driver
    hostname = d.instance.hostname
    port = d.instance.port
    tag = d.instance.tag
    reg_addr = d.instance.reg_addr
    nregs = d.instance.nregs
    modbus_retry = d.instance.modbus_retry
    
    begin
      ModBus::TCPClient.new(hostname, port) do |cl|
        cl.with_slave(modbus_retry) do |sl|
          @reg = sl.read_input_registers(reg_addr, nregs)
        end
      end
      assert_equal Array, @reg
    rescue => ex
        p ex.message
        p ex.backtrace.inspect
    end
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
end
