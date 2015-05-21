if defined?(ChefSpec)

  def create_mysql_database_user(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:mysql_database_user, :create, resource_name)
    # debugger
    # chef_run.resource_collection.each do |rsrc|
    #   puts rsrc.inspect
    # end
  end

  def create_mysql_database(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:mysql_database, :create, resource_name)
  end

  def grant_mysql_user(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:mysql_database_user, :grant, resource_name)
  end

end
