CREATE TABLE IF NOT EXISTS modbus.sensors(
    sensor_id INTEGER NOT NULL AUTO_INCREMENT,
    sensor_name VARCHAR(32) NOT NULL,
    host VARCHAR(32) NOT NULL,
    reg INTEGER NOT NULL,
    unit VARCHAR(32),
    PRIMARY KEY(sensor_id)
);

CREATE TABLE IF NOT EXISTS modbus.data_YYYYMM(
    id INTEGER NOT NULL AUTO_INCREMENT,
    sensor_id INTEGER NOT NULL,
    time DATETIME NOT NULL,
    raw_value FLOAT NOT NULL,
    value FLOAT,
    percentile FLOAT,
    PRIMARY KEY(id)
);
    
