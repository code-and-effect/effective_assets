require 'spec_helper'
require 'factory_girl_rails'

# Attributes
describe Effective::Asset do
  let(:asset) { FactoryGirl.create(:asset) }

  it 'should be valid' do
    asset.valid?.should eq true
  end
end

describe Effective::Asset do
  let(:image_file_string) { File.read(Rails.root.join('public/sprites.png')) }
  let(:image_url) { 'http://cdn.sstatic.net/stackoverflow/img/sprites.png?v=1' }

  let (:email) do
    Mail.new do
      from      'someone@something.com'
      to        'info@rails-skeleton.agilestyle.com'
      subject   'Test email'
      body      'This is the body of the test email'
    end
  end

  it 'should be creatable from URL' do
    asset = Effective::Asset.create_from_url(image_url, {:title => 'a title', :user_id => 1})

    # A new asset should exist, and it should be unprocessed
    asset.should_not eq false

    asset.upload_file.should eq image_url
    asset.processed.should eq false

    # It should have queued up a process_asset task with delayed job
    Delayed::Job.count.should eq 1

    job = Psych.load(Delayed::Job.first.handler)
    job.method_name.should eq :process_asset_without_delay
    job.args.first.should eq asset.id

    # Run DelayedJob
    Delayed::Worker.new(:max_priority => nil, :min_priority => nil, :quiet => true).work_off
    Delayed::Job.count.should eq 0

    # We should have a totally processed Asset
    asset = Effective::Asset.find(asset.id)
    asset.processed.should eq true
    asset.data.kind_of?(TestAssetUploader).should eq true
    asset.title.should eq 'a title'
    asset.user_id.should eq 1
    asset.versions_info.present?.should eq true
    asset.content_type.should eq 'image/png'
    asset.height.should eq 1073
    asset.width.should eq 238
  end

  it 'should be creatable from a String' do
    asset = Effective::Asset.create_from_string(image_file_string, :filename => 'sprites1.png', :content_type => 'image/png')

    # A new asset should exist, and it should be unprocessed
    asset.should_not eq false

    asset.upload_file.should eq "string://sprites1.png"
    asset.processed.should eq false

    # It should have queued up a process_asset task with delayed job
    Delayed::Job.count.should eq 1

    job = Psych.load(Delayed::Job.first.handler)
    job.method_name.should eq :process_asset_without_delay
    job.args.first.should eq asset.id

    # Run DelayedJob
    Delayed::Worker.new(:max_priority => nil, :min_priority => nil, :quiet => true).work_off
    Delayed::Job.count.should eq 0

    # We should have a totally processed Asset
    asset = Effective::Asset.find(asset.id)
    asset.processed.should eq true
    asset.data.kind_of?(TestAssetUploader).should eq true
    asset.title.should eq 'sprites1.png'
    asset.user_id.should eq 1
    asset.versions_info.present?.should eq true
    asset.content_type.should eq 'image/png'
    asset.height.should eq 1073
    asset.width.should eq 238
  end

  it 'should handle an email decoded string file' do
    email.add_file({:filename => Rails.root.join('public/sprites.png').to_s})

    attachment = email.attachments.first
    asset = Effective::Asset.create_from_string(attachment.body.decoded, :filename => attachment.filename, :content_type => attachment.mime_type)

    # A new asset should exist, and it should be unprocessed
    asset.should_not eq false

    asset.upload_file.include?('public_sprites.png').should eq true
    asset.upload_file.include?('string://').should eq true
    asset.processed.should eq false


    # It should have queued up a process_asset task with delayed job
    Delayed::Job.count.should eq 1

    job = Psych.load(Delayed::Job.first.handler)
    job.method_name.should eq :process_asset_without_delay
    job.args.first.should eq asset.id

    # Run DelayedJob
    Delayed::Worker.new(:max_priority => nil, :min_priority => nil, :quiet => true).work_off
    Delayed::Job.count.should eq 0

    # We should have a totally processed Asset
    asset = Effective::Asset.find(asset.id)
    asset.processed.should eq true
    asset.data.kind_of?(TestAssetUploader).should eq true
    asset.user_id.should eq 1
    asset.versions_info.present?.should eq true
    asset.content_type.should eq 'image/png'
    asset.height.should eq 1073
    asset.width.should eq 238


  end

end
