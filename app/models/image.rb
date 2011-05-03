require 'aws/s3'
require 'digest/sha1'

class Image < ActiveRecord::Base

  SEP_CHAR = '/'
  @@storage_bucket = nil
  attr_accessor :tmp_path, :ts
  
  validates :filename, :presence => true
  before_create :upload_s3
  
  # TODO: ensure filename is unique
  def self.from_upload(name, tmp_path)
    image = Image.new(:filename => name, :tmp_path => tmp_path, :ts => Time.now.to_i)
    image.base_url = [ts, 0].join(SEP_CHAR)
  end
  
  # Produces a unique filename for an image based on the hash passed to it
  # e.g. Image.hashed_filename("myphoto.gif", {:one => 1, :two => "2"}) -> myphoto-12fabacd234[...].gif
  def self.hashed_filename(filename, options)
    filename_parts = filename.split('.')
    if filename_parts.size >= 2
      filename_parts[0] + '-' + Digest::SHA1.hexdigest(options.to_s) + "." + filename_parts[1]
    else
      nil
    end
  end
    
  def self.storage_bucket
    @@storage_bucket ||= YAML::load(File.open(File.join(Rails.root, 'config', 'aws.yaml')))['aws']['bucket']
  end
  
  # Retrieves a file object from S3, returns nil if none exists
  def self.fetch_io(image_filename)
    image = find_by_filename(image_filename)
    logger.info("Found #{image.s3_key}")
    if image
      s3_image = AWS::S3::S3Object.find(image.s3_key, storage_bucket)
      StringIO.new s3_image.value
    end
  end
  
  def s3_key
    #s3_prefix + SEP_CHAR + "#{filename}"
    [base_url, filename].join(SEP_CHAR)
  end

private
  
  def upload_s3
    self.base_url = s3_prefix
    
    begin
      AWS::S3::S3Object.store(s3_key, open(tmp_path), storage_bucket)
      self.uploaded = true
    rescue AWS::S3::ResponseError => error
      logger.error(error.inspect)
      return false
    end
  end
  
  # The S3 identifier used for the image
  def s3_prefix
    [ts, revision].join(SEP_CHAR)
  end
  

end
