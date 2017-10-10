require 'sqlite3'
require 'pg'
require 'active_support/inflector'

module Associations
  def has_many(association)
    define_method(association) do
      if BlocRecord.platform == :sqlite3
        rows = self.class.connection.execute <<-SQL
          SELECT * FROM #{association.to_s.singularize}
          WHERE #{self.class.table}_id = #{self.id}
        SQL
      elsif BlocRecord.platform == :pg
        rows = self.class.connection.query(
          "SELECT * FROM #{association.to_s.singularize}
          WHERE #{self.class.table}_id = #{self.id}"
        ).values
      end
      class_name = association.to_s.classify.constantize
      collection = BlocRecord::Collection.new
      rows.each do |row|
        collection << class_name.new(Hash[class_name.columns.zip(row)])
      end

      collection
    end
  end

  def belongs_to(association)
    define_method(association) do
      association_name = association.to_s
      if BlocRecord.platform == :sqlite3
        row = self.class.connection.get_first_row <<-SQL
          SELECT * FROM #{association_name}
          WHERE id = #{self.send(association_name + "_id")}
        SQL
      elsif BlocRecord.platform == :pg
        row = self.class.connection.exec(
          "SELECT * FROM #{association_name}
          WHERE id = #{self.send(association_name + "_id")}"
        )
      end
      class_name = association_name.classify.constantize

      if row
        data = Hash[class_name.columns.zip(row)]
        class_name.new(data)
      end
    end
  end

  def has_one(association)
    define_method(association) do
      association_name = association.to_s
      if BlocRecord.platform == :sqlite3
        row = self.class.connection.get_first_row <<-SQL
          SELECT * FROM #{association_name}
          WHERE id = #{self.send(association_name + "_id")}
        SQL
      elsif BlocRecord.platform == :pg
        row = self.class.connection.exec(
          "SELECT * FROM #{association_name}
          WHERE id = #{self.send(association_name + "_id")}"
        )
      end

      class_name = association_name.classify.constantize

      if row
        data = Hash[class_name.columns.zip(row)]
        class_name.new(data)
      end
    end
  end
end
