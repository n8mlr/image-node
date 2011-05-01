require 'aws/s3'

class Image < ActiveRecord::Base

  cattr_accessor :storage_bucket
  attr_accessor :tmp_path, :ts
  
  validates :filename, :presence => true
  before_create :upload_s3
  
  def self.from_upload(name, tmp_path)
    image = Image.new(:filename => name, :tmp_path => tmp_path, :ts => Time.now.to_i)
  end

private

  def upload_s3
    self.base_url = s3_key
    raise "Remote bucket not set" unless storage_bucket
    
    begin
      AWS::S3::S3Object.store(s3_key, open(tmp_path), storage_bucket)
    rescue AWS::S3::ResponseError => error
      logger.error(error.inspect)
      return false
    end
  end
  
  # The S3 identifier used for the image
  def s3_key
    [ts, revision, filename].join('/')
  end
end
