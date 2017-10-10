module BlocRecord
  class Collection < Array
    def update_all(updates)
      ids = self.map(&:id)
      self.any? ? self.first.class.update(ids, updates) : false
    end

    def where(arguments)
      key = arguments.keys.first
      value = arguments.values.first
      new_collection = Collection.new
      self.each do |entry|
        if entry.send(key) == value
          new_collection << entry
        end
      end
      new_collection
    end

    def take(count = 1)
      new_collection = Collection.new
      entry = 0
      count.times do
        new_collection << self[entry]
        entry += 1
      end
      new_collection
    end

    def destroy_all
      self.each do |entry|
        entry.destroy
      end
    end
  end
end
