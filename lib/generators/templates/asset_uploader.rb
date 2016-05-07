class AssetUploader < EffectiveAssetsUploader
  # resize_to_fit
  # Resize the image to fit within the specified dimensions while retaining the
  # original aspect ratio. The image may be shorter or narrower than specified in the smaller dimension
  # but will not be larger than the specified values.
  #
  # Probably best for taking a big image and making it smaller.
  # Keeps the aspect ratio
  # An uploaded image that is smaller will not be made bigger.

  # resize_to_fill
  # Resize the image to fit within the specified dimensions while retaining the
  # aspect ratio of the original image. If necessary, crop the image in the larger dimension.

  # resize_to_limit
  # http://stackoverflow.com/questions/8570181/carrierwave-resizing-images-to-fixed-width
  # Keep in mind, resize_to_fit will scale up images if they are smaller than 100px.
  # If you don't want it to do that, then replace that with resize_to_limit.

  version :thumb, :if => :image? do
    process :resize_to_fit => [70, 70]
    process :record_info => :thumb
    # process :watermark! => [70, 70]
    # process :grayscale!
    # process :transparent! => ['#3F7F42', '12%']
  end

  # If you want to do a watermark, you can use something like this
  # def watermark!(width, height)
  #   manipulate! do |image|
  #     logo = MiniMagick::Image.open("#{ Rails.root }/app/assets/images/watermark.png")
  #     logo.resize("#{ width }x#{ height }>")
  #     result = image.composite(logo) do |comp|
  #       comp.gravity "center"
  #     end
  #   end
  # end

  # If you want to Grayscale images, you can use something like this
  # def grayscale!
  #   manipulate! do |image|
  #     image.colorspace("Gray")
  #     image = yield(image) if block_given?
  #     image
  #   end
  # end

  # If you want to make a certain color in the image transparent (assumes gif or png), you can use something like this
  # def transparent!(color, fuzz)
  #   manipulate! do |image|
  #     image.transparent(color) do |cmd|
  #       cmd.fuzz fuzz
  #     end
  #
  #     image = yield(image) if block_given?
  #     image
  #   end
  # end

  # Auto Orient
  # def auto_orient
  #   manipulate! do |image|
  #     image.auto_orient
  #     image
  #   end
  # end

  # Rotate counter clockwise
  # def rotate_ccw
  #   manipulate! do |image|
  #     image.rotate(-90)
  #     image
  #   end
  # end

end
