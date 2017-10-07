module BlocRecord

  def self.connect_to(filename, platform)
    @database_filename = filename
    @platform = platform
  end

  def self.platform
    @platform
  end
  
  def self.database_filename
    @database_filename
  end
end
