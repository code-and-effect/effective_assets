module Effective
  class Asset < ActiveRecord::Base
    self.table_name = EffectiveAssets.assets_table_name.to_s

    mount_uploader :data, EffectiveAssets.uploader

    belongs_to :user if defined?(User)
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
      upload_file     :string, :validates => [:presence]    # The full url of the file, as originally uploaded

      processed       :boolean, :default => false
      aws_acl         :string, :default => 'public-read', :validates => [:presence, :inclusion => {:in => ['public-read', 'authenticated-read']}]

      data            :string

      data_size       :integer
      height          :integer, :validates => [:numericality => { :allow_nil => true }]
      width           :integer, :validates => [:numericality => { :allow_nil => true }]

      versions_info   :text   # We store a hash of {:thumb => 34567, :medium => 3343434} data sizes

      timestamps
    end

    serialize :versions_info, Hash

    before_validation :set_content_type
    before_save :update_asset_dimensions
    after_commit :enqueue_delayed_job

    default_scope -> { order('created_at DESC') }

    scope :images, -> { where('content_type LIKE ?', '%image%') }
    scope :videos, -> { where('content_type LIKE ?', '%video%') }
    scope :audio, -> { where('content_type LIKE ?', '%audio%') }
    scope :files, -> { where('(content_type NOT LIKE ?) AND (content_type NOT LIKE ?) AND (content_type NOT LIKE ?)', '%image%', '%video%', '%audio%') }

    scope :today, -> { where("created_at >= ?", Time.zone.today.beginning_of_day) }
    scope :this_week, -> { where("created_at >= ?", Time.zone.today.beginning_of_week) }
    scope :this_month, -> { where("created_at >= ?", Time.zone.today.beginning_of_month) }

    class << self
      def s3_base_path
        "https://#{EffectiveAssets.aws_bucket}.s3.amazonaws.com/"
      end

      def string_base_path
        "string://"
      end

      # Just call me with Asset.create_from_url('http://somewhere.com/somthing.jpg')
      def create_from_url(url, options = {})
        opts = {:upload_file => url, :user_id => 1, :aws_acl => EffectiveAssets.aws_acl}.merge(options)

        asset = Asset.new(opts)
        asset.save ? asset : false
      end

      # This loads the raw contents of a string into a file and uploads that file to s3
      # Expect to be passed something like
      # Asset.create_from_string('some binary stuff from a string', :filename => 'icon_close.png', :content_type => 'image/png')
      def create_from_string(str, options = {})
        filename = options.delete(:filename) || "file-#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}.txt"

        filename = URI.escape(filename).gsub(/%\d\d|[^a-zA-Z0-9.-]/, '_')  # Replace anything not A-Z, a-z, 0-9, . -

        opts = {:upload_file => "#{Asset.string_base_path}#{filename}", :user_id => 1, :aws_acl => EffectiveAssets.aws_acl}.merge(options)

        asset = Asset.new(opts)
        asset.data = AssetStringIO.new(filename, str)

        asset.save ? asset : false
      end
    end # End of Class methods

    def title
      self[:title].presence || URI.unescape(file_name)
    end

    def url(version = nil)
      aws_acl == 'authenticated-read' ? authenticated_url(version) : public_url(version)
    end

    def public_url(version = nil)
      uri = "#{Asset.s3_base_path.chomp('/')}/#{EffectiveAssets.aws_path.chomp('/')}/#{id.to_i}/#{upload_file.to_s.split('/').last}"
      version.present? ? uri.insert(uri.rindex('/')+1, "#{version.to_s}_") : uri
    end

    def authenticated_url(version = nil, expire_in = 10.minutes)
      data.fog_authenticated_url_expiration = expire_in
      version.present? ? data.send(version).file.authenticated_url : data.file.authenticated_url
    end

    def file_name
      upload_file.to_s.split('/').last rescue upload_file
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

    def versions_info
      self[:versions_info] || {}
    end

    def upload_file=(upload_file)
      self[:upload_file] = URI.escape(upload_file || '')
    end

    def to_s
      title
    end

    protected

    def set_content_type
      if [nil, 'null', 'unknown', 'application/octet-stream', ''].include?(content_type)
        self.content_type = case File.extname(public_url).downcase
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
          when '.txt' ; 'text/plain'
          when '.doc' ; 'application/msword'
          when '.docx' ; 'application/msword'
          else ; 'unknown'
        end
      end
    end

    def update_asset_dimensions
      if data.present? && data_changed? && image?
        begin
          image = MiniMagick::Image.open(self.data.path)
          self.width = image[:width]
          self.height = image[:height]
        rescue => e
        end
      end
      true
    end

    def enqueue_delayed_job
      if !self.processed && self.upload_file.present? && self.upload_file != 'placeholder'
        Effective::DelayedJob.new.process_asset(self)
      end
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

