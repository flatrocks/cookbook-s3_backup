require_relative "../spec_helper"

describe "test::s3_mysql_backup_resource" do

  subject { ChefSpec::SoloRunner.new(:step_into => ["s3_mysql_backup"]) do |node|
  end.converge(described_recipe) }
  before do
  end

  describe 'required libraries' do
    it 'includes recipe ruby' do
      expect(subject).to include_recipe 'ruby'
    end
    it 'installs gem package aws-sdk' do
      expect(subject).to install_gem_package  'aws-sdk'
    end
  end

  describe "the system user" do
    it "is created" do
      expect(subject).to create_user("my_backup")
    end
     it "has the right groups" do
      expect(subject).to create_group("group group1 appending user my_backup").with_group_name("group1").with_append(true).with_members ["my_backup"]
      expect(subject).to create_group("group group2 appending user my_backup").with_group_name("group2").with_append(true).with_members ["my_backup"]
    end
  end

  describe "the temp dir" do
    it "is created" do
      expect(subject).to create_directory("/home/my_backup/temp")
    end
  end

  describe "the script file" do
    it "is created" do
      expect(subject).to create_cookbook_file("/home/my_backup/s3_mysql_backup.rb")
    end
    it "is from the right source" do
      expect(subject).to create_cookbook_file("/home/my_backup/s3_mysql_backup.rb").with_source "s3_mysql_backup.rb"
      expect(subject).to render_file("/home/my_backup/s3_mysql_backup.rb").with_content /.+/ # pass only if source actually exists
    end
    it "has the right user, group, and mode" do
      expect(subject).to create_cookbook_file("/home/my_backup/s3_mysql_backup.rb").with_user "my_backup"
      expect(subject).to create_cookbook_file("/home/my_backup/s3_mysql_backup.rb").with_group "my_backup"
      expect(subject).to create_cookbook_file("/home/my_backup/s3_mysql_backup.rb").with_mode "500"
    end
  end

  describe "the config.yml file" do
    it "is created" do
      expect(subject).to create_file("/home/my_backup/config.yml")
    end
    it "has the right user, group, and mode" do
      expect(subject).to create_file("/home/my_backup/config.yml").with_user "my_backup"
      expect(subject).to create_file("/home/my_backup/config.yml").with_group "my_backup"
      expect(subject).to create_file("/home/my_backup/config.yml").with_mode "400"
    end
    it "has the right content" do
      # each element, but not testing line order :-/
      [
        "s3:\n" +
        "  region: us-east-1\n" +
        "  access_key_id: my_access_key_id\n" +
        "  secret_access_key: my_secret_access_key\n" +
        "  bucket: my_bucket\n" +
        "  time_prefix: '%d-%b-%Y'",
        "log:\n" +
        "  ident: s3_mysql_backup\n" +
        "backup_groups:\n" +
        "  default:\n" +
        "  - db1\n" +
        "  catalogs:\n" +
        "  - db2 table1 table2\n"
      ].each do |fragment|
        expect(subject).to render_file("/home/my_backup/config.yml").with_content fragment
      end
    end
  end

  describe 'the mysql_database_user' do
    it 'is created' do
      expect(subject).to create_mysql_database_user('my_backup')
    end
    it 'it has the correct password' do
      expect(subject).to create_mysql_database_user('my_backup').with_password 'some_password'
    end
    it 'it has the correct database_connection' do
      expect(subject).to create_mysql_database_user('my_backup').with_connection :host=>"127.0.0.1", :user=>"root", :password=>"somepw"
    end
    it 'has lock table privilege' do
      expect(subject).to grant_mysql_database_user('my_backup on *').with_privileges ['LOCK TABLES']
    end
    it 'has select privileges for the required databases' do
      expect(subject).to grant_mysql_database_user('my_backup on db1').with_database_name('db1').with_privileges [:select]
      expect(subject).to grant_mysql_database_user('my_backup on db2').with_database_name('db2').with_privileges [:select]
    end
  end

  describe 'the mysql.cnf file' do
    it 'has the right content' do
      [
        "[client]\n",
        "host=127.0.0.1\n",
        "user=user1\n",
        "password=some_password\n"
      ].each do |fragment|
        expect(subject).to render_file("/home/my_backup/.my.cnf").with_content fragment
      end
    end
    it 'has the right owner, group and mode' do
      expect(subject).to create_template('/home/my_backup/.my.cnf').with_owner 'my_backup'
      expect(subject).to create_template('/home/my_backup/.my.cnf').with_group 'my_backup'
      expect(subject).to create_template('/home/my_backup/.my.cnf').with_mode '400'
    end
  end

  describe "the cron job" do
    it "is created" do
      expect(subject).to create_cron("cron for my_backup s3 mysql backup")
    end
    it "has the right user" do
      expect(subject).to create_cron("cron for my_backup s3 mysql backup").with_user "my_backup"
    end
    it "has the right command" do
      expect(subject).to create_cron("cron for my_backup s3 mysql backup").with_command "ruby s3_mysql_backup.rb"
    end
    it "has the right scheduling attributes" do
      expect(subject).to create_cron("cron for my_backup s3 mysql backup").with_day '*'
      expect(subject).to create_cron("cron for my_backup s3 mysql backup").with_hour '10,14,16'
    end
  end

end