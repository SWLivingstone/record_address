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
         @schema = connection.query(
          "SELECT * FROM #{table} LIMIT 1"
         ).first.keys
       end
     end
     @schema
  end

  def columns
    if BlocRecord.platform == :sqlite3
      schema.keys
    elsif BlocRecord.platform == :pg
      schema
    end
  end

  def attributes
     columns - ["id"]
  end

  def count
    if BlocRecord.platform == :sqlite3
      connection.execute(<<-SQL)[0][0]
        SELECT COUNT(*) FROM #{table}
      SQL
    elsif BlocRecord.platform == :pg
      connection.exec(
      "SELECT COUNT(*) FROM #{table}"
      )
    end
  end
end
