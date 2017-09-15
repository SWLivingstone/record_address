
 require 'sqlite3'

 module Selection

   def find(*ids)
     if not_valid_int(ids)
       p "One or more of your inputs was not a valid record ID"
       return nil
     end
     if ids.length == 1
       find_one(ids.first)
     else
       rows = connection.execute <<-SQL
         SELECT #{columns.join ","} FROM #{table}
         WHERE id IN (#{ids.join(",")});
       SQL

       rows_to_array(rows)
     end
   end

   def find_one(id)
     if not_valid_int(id)
       p "Not a valid input for record ID"
       return nil
     end
     row = connection.get_first_row <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       WHERE id = #{id};
     SQL

     init_object_from_row(row)
   end

   def find_each(start = false, batch_size = false)
     if start == false
       rows = connection.execute <<-SQL
       SELECT #{columns.join ","} FROM #{table};
       SQL
     else
       rows = connection.execute <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       LIMIT #{batch_size.to_s} OFFSET #{start.to_s};
       SQL
     end
      rows_to_array(rows)
   end

   def find_in_batches(start, batch_size)
     rows = connection.execute <<-SQL
     SELECT #{columns.join ","} FROM #{table}
     LIMIT #{batch_size.to_s} OFFSET #{start.to_s};
     SQL
     rows_to_array(rows)
   end

   def find_by(attribute, value)
     row = connection.get_first_row <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
     SQL

     init_object_from_row(row)
   end

   def take(num=1)
     if not_valid_int(num)
       p "Not a valid number"
       return nil
     end
     if num > 1
       rows = connection.execute <<-SQL
         SELECT #{columns.join ","} FROM #{table}
         ORDER BY random()
         LIMIT #{num};
       SQL

       rows_to_array(rows)
     else
       take_one
     end
   end

   def take_one
     row = connection.get_first_row <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       ORDER BY random()
       LIMIT 1;
     SQL

     init_object_from_row(row)
   end

   def first
     row = connection.get_first_row <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       ORDER BY id ASC LIMIT 1;
     SQL

     init_object_from_row(row)
   end

   def last
     row = connection.get_first_row <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       ORDER BY id DESC LIMIT 1;
     SQL

     init_object_from_row(row)
   end

   def all
     rows = connection.execute <<-SQL
       SELECT #{columns.join ","} FROM #{table};
     SQL

     rows_to_array(rows)
   end

   def method_missing(symbol, *args)
     attribute = symbol.to_s.split("_").last
     self.find_by(attribute.to_sym, args[0])
   end

   private

   def not_valid_int(*id)
     id.each do |n|
       if n.is_a? Integer and n > 0
         return false
       else
         return true
       end
     end
   end

   def init_object_from_row(row)
     if row
       data = Hash[columns.zip(row)]
       new(data)
     end
   end

   def rows_to_array(rows)
     rows.map { |row| new(Hash[columns.zip(row)]) }
   end
 end
