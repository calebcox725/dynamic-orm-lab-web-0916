require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{table_name}')"
    table_info = DB[:conn].execute(sql)
    
    column_names = table_info.each_with_object([]) do |row, column_names|
      column_names << row["name"]
    end
    column_names.compact
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

  def self.find_by(options = {})

    options_for_select = options.each_with_object([]) do |property_arr, options|
      column = property_arr[0].to_s

      if property_arr[1].is_a?(Integer)
        value = property_arr[1]
      else
        value = "'#{property_arr[1]}'"
      end

      options << "#{column} = #{value} "
    end

    sql = "SELECT * FROM #{table_name} WHERE
      #{options_for_select.join(" AND ")}
    "

    DB[:conn].execute(sql)
  end

  def initialize(options = {})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if { |col| col == "id"}.join(", ")
  end

  def values_for_insert
    values = self.class.column_names.each_with_object([]) do |col, values|
      values << "'#{send(col)}'" unless send(col).nil?
    end
    values.join(", ")
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert})
      VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)

    @id = DB[:conn].execute("SELECT last_insert_rowid()
      #{table_name_for_insert}")[0][0]
  end

end