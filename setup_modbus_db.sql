create database if not exists modbus_debug;
create table if not exists modbus_debug.modbus
    (
        modbus_id int not null primary key,
        modbus_name varchar(32),
        host_id integer
    );
create table if not exists modbus_debug.host
    (
        host_id int not null primary key,
        host_name varchar(32)
    );
create table if not exists modbus_debug.data_201304
    (
        time int not null auto_increment primary key,
        raw     integer,
        value   integer,
        modbus_id   integer
    );
