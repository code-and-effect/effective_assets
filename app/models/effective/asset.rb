module Effective
  class Asset < ActiveRecord::Base
    self.table_name = EffectiveAssets.assets_table_name.to_s

    mount_uploader :data, (EffectiveAssets.uploader.kind_of?(String) ? EffectiveAssets.uploader.constantize : EffectiveAssets.uploader)

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

    has_many :attachments, dependent: :delete_all

    # structure do
    #   title           :string
    #   extra           :text

    #   content_type    :string
    #   upload_file     :string    # The full url of the file, as originally uploaded

    #   processed       :boolean, :default => false
    #   aws_acl         :string, :default => 'public-read'

    #   data            :string

    #   data_size       :integer
    #   height          :integer
    #   width           :integer

    #   versions_info   :text   # We store a hash of {:thumb => 34567, :medium => 3343434} data sizes

    #   timestamps
    # end

    validates :content_type, presence: true
    validates :upload_file, presence: true
    validates :aws_acl, presence: true, inclusion: { in: [EffectiveAssets::AWS_PUBLIC, EffectiveAssets::AWS_PRIVATE] }
    validates :height, numericality: { allow_nil: true }
    validates :width, numericality: { allow_nil: true }

    serialize :versions_info, Hash
    serialize :extra, Hash

    before_validation :set_content_type
    before_save :update_asset_dimensions
    after_commit :queue_async_job

    default_scope -> { order(:id) }
    scope :nonplaceholder, -> { where("#{EffectiveAssets.assets_table_name}.upload_file != ?", 'placeholder') }

    scope :images, -> { nonplaceholder().where("#{EffectiveAssets.assets_table_name}.content_type LIKE ?", '%image%') }
    scope :nonimages, -> { nonplaceholder().where("(#{EffectiveAssets.assets_table_name}.content_type NOT LIKE ?)", '%image%') }

    scope :videos, -> { nonplaceholder().where("#{EffectiveAssets.assets_table_name}.content_type LIKE ?", '%video%') }
    scope :audio, -> { nonplaceholder().where("#{EffectiveAssets.assets_table_name}.content_type LIKE ?", '%audio%') }
    scope :files, -> { nonplaceholder().where("(#{EffectiveAssets.assets_table_name}.content_type NOT LIKE ?) AND (#{EffectiveAssets.assets_table_name}.content_type NOT LIKE ?) AND (#{EffectiveAssets.assets_table_name}.content_type NOT LIKE ?)", '%image%', '%video%', '%audio%') }

    scope :today, -> { nonplaceholder().where("#{EffectiveAssets.assets_table_name}.created_at >= ?", Time.zone.today.beginning_of_day) }
    scope :this_week, -> { nonplaceholder().where("#{EffectiveAssets.assets_table_name}.created_at >= ?", Time.zone.today.beginning_of_week) }
    scope :this_month, -> { nonplaceholder().where("#{EffectiveAssets.assets_table_name}.created_at >= ?", Time.zone.today.beginning_of_month) }

    class << self
      def s3_base_path
        "https://#{EffectiveAssets.aws_bucket}.s3.amazonaws.com/"
      end

      def string_base_path
        "string://"
      end

      # Just call me with Asset.create_from_url('http://somewhere.com/somthing.jpg')
      def create_from_url(url, options = {})
        opts = { upload_file: url, user_id: 1, aws_acl: EffectiveAssets.aws_acl }.merge(options)

        attempts = 3  # Try to upload this string file 3 times
        begin
          asset = Asset.new(opts)

          if asset.save
            asset
          else
            puts asset.errors.inspect
            Rails.logger.info asset.errors.inspect
            false
          end
        rescue => e
          (attempts -= 1) >= 0 ? (sleep 2; retry) : false
        end
      end

      # This loads the raw contents of a string into a file and uploads that file to s3
      # Expect to be passed something like
      # Asset.create_from_string('some binary stuff from a string', :filename => 'icon_close.png', :content_type => 'image/png')
      def create_from_string(str, options = {})
        filename = options.delete(:filename) || "file-#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}.txt"

        filename = URI.escape(filename).gsub(/%\d\d|[^a-zA-Z0-9.-]/, '_')  # Replace anything not A-Z, a-z, 0-9, . -

        opts = { upload_file: "#{Asset.string_base_path}#{filename}", user_id: 1, aws_acl: EffectiveAssets.aws_acl }.merge(options)

        attempts = 3  # Try to upload this string file 3 times
        begin
          asset = Asset.new(opts)
          asset.data = AssetStringIO.new(filename, str)

          if asset.save
            asset
          else
            puts asset.errors.inspect
            Rails.logger.info asset.errors.inspect
            false
          end
        rescue => e
          (attempts -= 1) >= 0 ? (sleep 2; retry) : false
        end

      end
    end # End of Class methods

    def to_s
      title
    end

    def title
      self[:title].presence || file_name
    end

    def extra
      self[:extra] || {}
    end

    def url(version = nil, expire_in: nil)
      aws_acl == EffectiveAssets::AWS_PRIVATE ? authenticated_url(version, expire_in: expire_in) : public_url(version)
    end

    def public_url(version = nil)
      if data.present?
        url = (version.present? ? data.send(version).file.try(:public_url) : data.file.try(:public_url))
        url || '#'
      else
       "#{Asset.s3_base_path.chomp('/')}/#{EffectiveAssets.aws_path.chomp('/')}/#{id.to_i}/#{file_name}"
      end
    end

    def authenticated_url(version = nil, expire_in: nil)
      if data.present?
        data.aws_authenticated_url_expiration = (expire_in || 60.minutes).to_i
        (version.present? ? data.send(version).file.try(:authenticated_url) : data.file.try(:authenticated_url))
      end || '#'
    end

    def file_name
      upload_file.to_s.split('/').last.gsub(/\?.+/, '') rescue upload_file
    end

    def video?
      content_type.include? 'video/'
    end

    def image?
      content_type.include? 'image/'
    end

    def icon?
      content_type.include? 'image/x-icon'
    end

    def audio?
      content_type.include? 'audio/'
    end

    def placeholder?
      upload_file.blank? || upload_file == 'placeholder'.freeze
    end

    def versions_info
      self[:versions_info] || {}
    end

    # This method is called asynchronously by an after_commit filter
    def process!
      if placeholder?
        puts 'Placeholder Asset processing not required (this is a soft error)'
        # Do nothing
      elsif image? == false
        puts 'Non-image Asset processing not required'
        # Do Nothing
      elsif upload_file.include?(Effective::Asset.string_base_path)
        puts 'String-based Asset processing and uploading'
        data.recreate_versions!
      elsif upload_file.include?(Effective::Asset.s3_base_path)
        # Carrierwave must download the file, process it, then upload the generated versions to S3
        puts 'S3 Uploaded Asset downloading and processing'

        self.remote_data_url = url
      else
        puts 'Non S3 Asset downloading and processing'
        puts "Downloading #{upload_file}"

        self.remote_data_url = upload_file
      end

      self.processed = true
      save!
    end
    alias_method :reprocess!, :process!

    # This will set the AWS permission to aws_acl
    def sync_aws_acl!
      if aws_acl == EffectiveAssets::AWS_PRIVATE
        if Net::HTTP.get_response(URI(public_url)).code.to_i != 403  # Forbidden
          self.remote_data_url = public_url
          save!
        end
      else
        # Make sure I can access it at the public url
        if Net::HTTP.get_response(URI(public_url)).code.to_i != 200  # Success
          self.remote_data_url = authenticated_url
          save!
        end
      end
    end

    protected

    def set_content_type
      if [nil, 'null', 'unknown', 'application/octet-stream', ''].include?(content_type)
        self.content_type = case File.extname(file_name.to_s.downcase.gsub(/\?.+/, ''))
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
          when '.xls' ; 'application/excel'
          when '.xlsx' ; 'application/excel'
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

    def queue_async_job
      return if processed? || placeholder?

      if EffectiveAssets.async == false
        return Effective::ProcessWithActiveJob.perform_now(id)
      end

      if [:inline, :async, nil].include?((Rails.application.config.active_job[:queue_adapter] rescue nil))
        Effective::ProcessWithSuckerPunchJob.perform_async(id)
      else
        Effective::ProcessWithActiveJob.perform_later(id)
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

