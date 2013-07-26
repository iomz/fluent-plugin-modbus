# Fluent::Plugin::Modbus

Fluent plugin to retrieve data from Modbus device and store the values into mysql

## Installation

    $ git clone https://github.com/iomz/fluent-plugin-modbus.git
    $ cd fluent-plugin-modbus & bundle

## Usage

    $ mysql -u root -p
    mysql> CREATE USER 'modbus'@'localhost' IDENTIFIED BY 'modbus_pw';
    mysql> CREATE DATABASE 'modbus_db';
    mysql> GRANT ALL PRIVILEGES ON modbus_db.* to 'modbus'@'localhost';
    mysql> FLUSH PRIVILEGES;
    mysql> QUIT;

    $ vim modbus.conf
    <source>
        type modbus
        tag modbus.sensor1     # An unique sensor name following 'modbus.'
        hostname 192.168.0.200 # ModBus host
        port 502               # ModBus port
        polling_time 0,30      # Poll data at seconds separated by colons
        modbus_retry 1         # Retry counts for TCP connection to ModBus host
        reg_size 16            # Register size of ModBus I/O device in bit
        reg_addr 0             # Address of the register to read
        nregs 1                # Number of sequential registers to read [1-2]
    </source>

    <match modbus.sensor1>
        type copy
        <store>
            type stdout
        </store>
        <store>
            type mysql_modbus
            dbhost 127.0.0.1       # DB host
            username modbus        # DB username
            password modbus_pw      # DB password
            database modbus_db        # Database to use
            max_modbus_input 10000 # Maximum value FROM ModBus I/O
            max_sensor_output 2000 # Maximum value TO ModBus I/O FROM sensor devices
            unit W/m^2             # Unit for the sensor device
        </store>
    </match>

    $ fluentd -c modbus.conf 

## TODO
More test cases needed

## Copyright

Copyright (c) 2012- Kenichi YASUKATA, Iori MIZUTANI

Apache License, Version 2.0
