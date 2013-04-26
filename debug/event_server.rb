require 'rubygems'
require 'eventmachine'

module FakeModbus
  def receive_data data
    flag = true
    p 'Receive Request and return 26'
    fake = "\x00\x01\x00\x00\x00\x06\x01\x03\x01\x00\x1a\x01"
    send_data(fake)
  end
end

EventMachine.run {
  EventMachine.start_server('localhost', 7000, FakeModbus)
}
