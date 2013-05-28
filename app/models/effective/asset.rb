module Effective
  class Asset < ActiveRecord::Base
    self.table_name = EffectiveAssets.assets_table_name.to_s

    mount_uploader :data, AssetUploader

    belongs_to :user if defined? User
    # This is the user that uploaded the asset.
    # We are using belongs_to because it makes all the permissions 'just work',
    # in letting people create assets.
    #
    # But this doesn't exactly belong to a user.
    # Assets belong to acts_as_asset_box enabled classes through attachments.
    #
    # 1.  The S3 uploader makes a post to s3_controller#create
    # 2.  The asset is created by the current_user
    # 3.  But it doesn't belong to anything yet.  It might be attached to a user's asset_boxes, or a page, or a post through attachments
    #

    has_many :attachments, :dependent => :delete_all

    structure do
      title           :string
      description     :text
      tags            :string

      content_type    :string, :validates => [:presence]
      upload_file     :string    # The full url of the file, as originally uploaded
      processed       :boolean, :default => false

      data            :string

      data_size       :integer
      height          :integer, :validates => [:numericality => { :allow_nil => true }]
      width           :integer, :validates => [:numericality => { :allow_nil => true }]

      versions_info   :text   # We store a hash of {:thumb => 34567, :medium => 3343434} data sizes

      timestamps
    end

    serialize :versions_info, Hash

    #attr_accessible :title, :description, :tags, :content_type, :data_size, :upload_file, :user, :user_id, :id
    #validates_presence_of :user_id

    before_save :update_asset_dimensions

    default_scope order('created_at DESC')

    scope :images, -> { where('content_type LIKE ?', '%image%') }
    scope :videos, -> { where('content_type LIKE ?', '%video%') }
    scope :audio, -> { where('content_type LIKE ?', '%audio%') }
    scope :files, -> { where('(content_type NOT LIKE ?) AND (content_type NOT LIKE ?) AND (content_type NOT LIKE ?)', '%image%', '%video%', '%audio%') }

    scope :today, -> { where("created_at >= ?", Date.today.beginning_of_day) }
    scope :this_week, -> { where("created_at >= ?", Date.today.beginning_of_week) }
    scope :this_month, -> { where("created_at >= ?", Date.today.beginning_of_month) }

    class << self
      def s3_base_path
        "http://#{EffectiveAssets.aws_bucket}.s3.amazonaws.com"
      end

      def string_base_path
        "string://"
      end

      # Just call me with Asset.create_from_url('http://somewhere.com/somthing.jpg')
      def create_from_url(url, options = {})
        opts = {:upload_file => url, :user_id => 1}.merge(options)

        if (asset = Asset.create(opts))
          Effective::DelayedJob.new.process_asset(asset)
          asset
        else
          false
        end
      end

      # We have just uploaded an asset via our s3 uploader
      # We want this image to be immediately available.
      def create_from_s3_uploader(url, options = {})
        opts = {:upload_file => "#{Asset.s3_base_path}/#{url}", :user_id => 1}.merge(options)

        asset = false

        Asset.transaction do
          begin
            asset = Asset.create!(opts)

            Rails.logger.info "Copying s3 uploaded file to final resting place..."
            storage = Fog::Storage.new(:provider => 'AWS', :aws_access_key_id => EffectiveAssets.aws_access_key_id, :aws_secret_access_key => EffectiveAssets.aws_secret_access_key)
            storage.copy_object(EffectiveAssets.aws_bucket, url, EffectiveAssets.aws_bucket, "#{EffectiveAssets.aws_final_path}#{asset.id}/#{asset.file_name}")
            storage.put_object_acl(EffectiveAssets.aws_bucket, "#{EffectiveAssets.aws_final_path}#{asset.id}/#{asset.file_name}", EffectiveAssets.aws_acl)

            Rails.logger.info "Deleting original..."
            directory = storage.directories.get(EffectiveAssets.aws_bucket)
            directory.files.new(:key => url).destroy

            asset.update_column(:upload_file, asset.url) # This is our upload file as far as CarrierWave is now concerned

            Effective::DelayedJob.new.process_asset(asset)
          rescue => e
            asset = false
          end

          raise ActiveRecord::Rollback unless asset
        end

        asset
      end

      # This loads the raw contents of a string into a file and uploads that file to s3
      # Expect to be passed something like
      # Asset.create_from_string('some binary stuff from a string', :filename => 'icon_close.png', :content_type => 'image/png')
      def create_from_string(str, options = {})
        filename = options.delete(:filename) || "file-#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}.txt"

        opts = {:upload_file => "#{Asset.string_base_path}#{filename}", :user_id => 1}.merge(options)

        asset = Asset.new(opts)
        asset.data = AssetStringIO.new(filename, str)

        if asset.save
          Effective::DelayedJob.new.process_asset(asset)
          asset
        end
      end
    end

    before_validation do
      if !content_type.present? or content_type == 'null' or content_type == 'unknown' or content_type == 'application/octet-stream'
        self.content_type = case url.to_s[-4, 4].downcase
          when '.mp3' ; 'audio/mp3'
          when '.mp4' ; 'video/mp4'
          when '.mov' ; 'video/mov'
          when '.m2v' ; 'video/m2v'
          when '.m4v' ; 'video/m4v'
          when '.3gp' ; 'video/3gp'
          when '.3g2' ; 'video/3g2'
          when '.avi' ; 'video/avi'
          when '.jpg' ; 'image/jpg'
          when '.gif' ; 'image/gif'
          when '.png' ; 'image/png'
          when '.bmp' ; 'image/bmp'
          when '.ico' ; 'image/x-icon'
          else ; 'unknown'
        end
      end
    end

    def title
      self[:title].present? ? self[:title] : file_name
    end

    # Return the final location of this asset
    def url
      "#{Asset.s3_base_path}/#{EffectiveAssets.aws_final_path}#{self.id}/#{upload_file.split('/').last}"
    end

    def file_name
      url.split('/').last rescue url
    end

    def video?
      content_type.include? 'video'
    end

    def image?
      content_type.include? 'image'
    end

    def icon?
      content_type.include? 'image/x-icon'
    end

    def audio?
      content_type.include? 'audio'
    end

    def as_json(options={})
      {:thumbnail => image_tag(:thumb).html_safe}.merge super
    end

    def still_processing?
      !processed
    end

    def versions_info
      self[:versions_info] || {}
    end

    protected
     # Called in the DelayedJob
     def update_asset_dimensions
      if data.present? and data_changed? and image?
        begin
          image = MiniMagick::Image.open(self.data.path)
          self.width = image[:width]
          self.height = image[:height]
        rescue => e
        end
      end
      true
    end
  end

  class AssetStringIO < StringIO
    attr_accessor :filepath

    def initialize(*args)
      super(*args[1..-1])
      @filepath = args[0]
    end

    def original_filename
      File.basename(filepath)
    end
  end
end

