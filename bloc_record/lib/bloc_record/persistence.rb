require 'sqlite3'
require 'pg'
require 'bloc_record/schema'

module Persistence

  def self.included(base)
     base.extend(ClassMethods)
  end

  def save
     self.save! rescue false
  end

  def save!
    unless self.id
      self.id = self.class.create(BlocRecord::Utility.instance_variables_to_hash(self)).id
      BlocRecord::Utility.reload_obj(self)
      return true
    end

   fields = self.class.attributes.map { |col| "#{col}=#{BlocRecord::Utility.sql_strings(self.instance_variable_get("@#{col}"))}" }.join(",")

   self.class.connection.execute <<-SQL
     UPDATE #{self.class.table}
     SET #{fields}
     WHERE id = #{self.id};
   SQL

   true
  end

  def update_attribute(attribute, value)
    self.class.update(self.id, { attribute => value })
  end

  def update_attributes(updates)
    self.class.update(self.id.to_i, updates)
  end

  def update_name(name)
    self.class.update(self.id, { 'name' => name})
  end

  def destroy
    self.class.destroy(self.id)
  end


  module ClassMethods
    def create(attrs)
      attrs = BlocRecord::Utility.convert_keys(attrs)
      attrs.delete "id"
      if BlocRecord.platform == :sqlite3
      vals = attributes.map { |key| BlocRecord::Utility.sql_strings(attrs[key]) }

        connection.execute <<-SQL
          INSERT INTO #{table} (#{attributes.join ","})
          VALUES (#{vals.join ","});
        SQL

        data = Hash[attributes.zip attrs.values]
        data["id"] = connection.execute("SELECT last_insert_rowid();")[0][0]
        new(data)
      elsif BlocRecord.platform == :pg
        data = attrs
        connection.exec(
          "INSERT INTO #{table} (#{attrs.keys.join ","})
          VALUES ('#{attrs.values.join "','"}')"
        )
        data["id"] = connection.exec("SELECT max(id) FROM #{table}").getvalue(0,0)
        data
      end
    end

    def update(ids, updates)
      if ids.kind_of?(Array) && updates.kind_of(Array)
        ids.each_with_index do |id, index|
          update(id, updates[index])
        end
      end

      updates = BlocRecord::Utility.convert_keys(updates)
      updates.delete "id"
      updates_array = updates.map { |key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}" }

      if ids.class == Fixnum #|| (ids.class == String && ids.length == 1)
        where_clause = "WHERE id = #{ids};"
      elsif ids.class == Array
        where_clause = ids.empty? ? ";" : "WHERE id IN (#{ids.join(",")});"
      else
        where_clause = ";"
      end

      if BlocRecord.platform == :sqlite3
        connection.execute <<-SQL
          UPDATE #{table}
          SET #{updates_array * ","} #{where_clause}
        SQL
      elsif BlocRecord.platform == :pg
        connection.exec(
          "UPDATE #{table}
          SET #{updates_array * ","} #{where_clause}"
        )
      end
      true
    end

    def update_all(updates)
      update(nil, updates)
    end

    def destroy(*id)
      if id.length > 1
        where_clause = "WHERE id IN (#{id.join(",")});"
      else
        where_clause = "WHERE id = #{id.first};"
      end
      if BlocRecord.platform == :sqlite3
        connection.execute <<-SQL
          DELETE FROM #{table} #{where_clause}
        SQL
      elsif BlocRecord.platform == :pg
        connection.exec(
          "DELETE FROM #{table} #{where_clause}"
        )
      end
      true
    end

    def destroy_all(*conditions_hash)
      if conditions_hash.is_a?(Array) || conditions_hash.is_a?(String)
        conditions_hash = BlocRecord::Utility.convert_to_hash(conditions_hash)
      end
      if conditions_hash && !conditions_hash.empty?
        conditions_hash = BlocRecord::Utility.convert_keys(conditions_hash)
        conditions = conditions_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")

        sql = <<-SQL
          DELETE FROM #{table}
          WHERE #{conditions};
        SQL
      else
        sql = <<-SQL
          DELETE FROM #{table}
        SQL
      end

      if BlocRecord.platform = :sqlite3
        connection.execute(sql)
      elsif BlocRecord.platform = :pg
        connection.exec(sql)
      end
      true
    end
  end
end
