# Fluent::Plugin::Modbus

Fluent plugin to retrieve data from Modbus device and store the values into mysql

## Installation

Add this line to your application's Gemfile:

    gem 'fluent-plugin-modbus'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-plugin-modbus

## Usage

    # modbus.conf
    <source>
        type modbus
        tag modbus.sensor1     # Tag for the data
        hostname 192.168.0.200 # ModBus host
        port 502               # ModBus port
        polling_time 0,30      # Poll data at seconds separated by colons
        modbus_retry 1         # Retry counts for TCP connection to ModBus host
        reg_size 16            # Register size of ModBus I/O device in bit
        reg_addr 0             # Address of the register to read
        nregs 1                # Number of sequential registers to read [1-2]
        max_input 10000        # Maximum value FROM ModBus I/O
        max_device_output 2000 # Maximum value TO ModBus I/O FROM sensor devices
        data_format %.2f       # String format to output (depending on the format type)
        unit W/m^2             # Unit for the sensor device
    </source>

    <match modbus.sensor1>
      type file
      path /var/log/modbus
    </match>

## TODO


## Copyright

Copyright (c) 2012- Kenichi YASUKATA, Iori MIZUTANI

Apache License, Version 2.0
