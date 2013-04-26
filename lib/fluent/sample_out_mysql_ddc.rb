require '/var/service/asama/local/lib/ruby/gems/1.9.1/gems/fluent-plugin-mysql-0.0.2/lib/fluent/plugin/out_mysql'

module Fluent
  class MysqlDDCOutput < MysqlOutput
    Plugin.register_output('mysql_ddc', self)

    def initialize
      super
      @file_id_cache = Hash.new
    end

    def format(tag, time, record)
      return [tag, time, record].to_msgpack
    end

    def write(chunk)
      init = {
        :host => @host,
        :port => @port,
        :username => @username,
        :password => @password,
        :database => @database
      }
      handler = Mysql2::Client.new(init)

      chunk.msgpack_each do |tag,time,data|

        file_id = @file_id_cache["#{data["filename"]}"]
        if file_id.nil?
          file_id = get_file_id(handler,data["filename"])
          @file_id_cache["#{data["filename"]}"] = file_id
        end

        month_table = "data_" + Time.at(time).strftime("%Y%m")
        sql = "INSERT INTO #{month_table} (time, value, file_id) VALUES (#{time}, #{data["value"]}, #{file_id})"
        handler.query(sql)
      end

      handler.close
    end

    def get_file_id(handler,filename)
      sql = "SELECT file_id FROM file where file_name = '#{filename}'"
      result = handler.query(sql).each do |file_id|
        file_id.each do |key, value|
          return value
        end
      end
      if result.empty?
        set_file(handler,filename)
        get_file_id(handler,filename)
      end
    end

    def set_file(handler,filename)
      sql = "INSERT INTO file (file_name) VALUES ('#{filename}')"
      handler.query(sql)
    end

  end
end
