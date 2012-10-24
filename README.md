# Fluent::Plugin::Modbus

Fluent plugin to retrieve data from Modbus device 

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
      tag modbus.server1
      hostname 192.168.0.1
      port 12345 
      polling_time 0,10,20,30,40,50
    </source>

    <match modbus.b>
      type file
      path /var/log/modbus
    </match>

## TODO

* Develop unit system conversion for each devices
* Complete TestCase
* Detailed Register address configuration

## Copyright

Copyright:: Copyright (c) 2012- Kenichi Yasukata, Iori MIZUTANI
License::   Apache License, Version 2.0