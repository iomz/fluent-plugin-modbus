create database if not exists modbus;
create table if not exists modbus.sensors
    (
        sensor_id integer not null auto_increment primary key,
        sensor_name varchar(32),
        host varchar(32),
        port integer,
        unit varchar(32),
    );

/*
create table if not exists modbus.data
    (
        id integer not null auto_increment primary key,
        sensor_id integer,
        time integer not null,
        raw_value float,
        value float,
        percentile float,
    );
*/
