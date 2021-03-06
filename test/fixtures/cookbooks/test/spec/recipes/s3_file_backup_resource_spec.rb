require_relative "../spec_helper"

describe "test::s3_file_backup_resource" do

  subject { ChefSpec::SoloRunner.new(:step_into => ["s3_file_backup"]) do |node|
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
      expect(subject).to create_cookbook_file("/home/my_backup/s3_file_backup.rb")
    end
    it "is from the right source" do
      expect(subject).to create_cookbook_file("/home/my_backup/s3_file_backup.rb").with_source "s3_file_backup.rb"
      expect(subject).to render_file("/home/my_backup/s3_file_backup.rb").with_content /.+/ # pass only if source actually exists
    end
    it "has the right user, group, and mode" do
      expect(subject).to create_cookbook_file("/home/my_backup/s3_file_backup.rb").with_user "my_backup"
      expect(subject).to create_cookbook_file("/home/my_backup/s3_file_backup.rb").with_group "my_backup"
      expect(subject).to create_cookbook_file("/home/my_backup/s3_file_backup.rb").with_mode "500"
    end
  end

  describe "the config.yml file" do
    let(:expected_content) do
      [
         "s3:",
        "  region: us-east-1",
        "  access_key_id: my_access_key_id",
        "  secret_access_key: my_secret_access_key",
        "  bucket: my_bucket",
        "  time_prefix: '%Y-%m-%d'",
        "log:",
        "  ident: s3_file_backup",
        "backup_groups:",
        "  default:",
        "  - /some/file",
        "  a_prefix:",
        "  - /yet_another/file"
      ]
    end
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
      expected_content.each do |fragment|
        expect(subject).to render_file("/home/my_backup/config.yml").with_content fragment
      end
    end
    it "is correct on the whole" do
      expect(subject).to render_file("/home/my_backup/config.yml").with_content expected_content.join("\n")
    end
  end

  describe "the cron job" do
    it "is created" do
      expect(subject).to create_cron("cron for my_backup s3 file backup")
    end
    it "has the right user" do
      expect(subject).to create_cron("cron for my_backup s3 file backup").with_user "my_backup"
    end
    it "has the right command" do
      expect(subject).to create_cron("cron for my_backup s3 file backup").with_command "ruby s3_file_backup.rb"
    end
    it "has the right scheduling attributes" do
      expect(subject).to create_cron("cron for my_backup s3 file backup").with_day '*'
      expect(subject).to create_cron("cron for my_backup s3 file backup").with_hour '10,14,16'
    end
  end

end