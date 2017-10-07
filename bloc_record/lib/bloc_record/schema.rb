require 'sqlite3'
require 'pg'
require 'bloc_record/utility'

module Schema
  def table
     BlocRecord::Utility.underscore(name)
  end

  def schema
     unless @schema
       if BlocRecord.platform == :sqlite3
         @schema = {}
         connection.table_info(table) do |col|
           @schema[col["name"]] = col["type"]
         end
       elsif BlocRecord.platform == :pg
         @schema = {}
         connection.query("SELECT * FROM #{table} LIMIT 1").fields do |col|
           puts col
          @schema[col["name"]] = col["type"]
         end
       end
     end
     @schema
  end

  def columns
     schema.keys
  end

  def attributes
     columns - ["id"]
  end

  def count
     connection.execute(<<-SQL)[0][0]
       SELECT COUNT(*) FROM #{table}
     SQL
  end
end
