require 'tempfile'
require 'rmagick'

class ImagesController < ApplicationController
  
  def show
    # - compute filename with size constraint
    # - check if image exists in local cache
    #   - if not, retrieve from file store, proces, return
    image_opts = params.reject { |k,v| %w(controller action url format).include? k } 
    image_filename = params[:url] + ".#{params[:format]}"
    hashed_filename = image_opts.empty? ? image_filename : Image.hashed_filename(image_filename, image_opts)
    image_path = File.join(Rails.root, 'public', 'image-cache', hashed_filename)
    
    logger.info "Received request for " + 
                image_filename + " with options: " + 
                image_opts.inspect + " with hash name: " +
                hashed_filename
    
    if File.exist? image_path
      send_file image_path and return
    else
      image = Image.fetch_io(image_filename)
      if image
        compiled_image = Magick::Image::from_blob(image.read).last
        if params[:geom]
          compiled_image.change_geometry(params[:geom]) { |cols,rows,img| img.resize!(cols,rows) }
        end
        compiled_image.write(image_path)
        send_file image_path
      else
        render :text => "Not found"
      end
    end
  end
  
  def update
    logger.info "Your S3 bucket is #{Image.storage_bucket}"
    # TODO
    # - confirm file is an image
    filename = params[:filename] + "." + params[:format]
    tmp_file = Tempfile.new(filename, File.join(Rails.root, 'tmp', 'images'))
    File.open(tmp_file, 'wb') {|f| f.write(request.body.read) }
    image = Image.from_upload(filename, tmp_file.path)
    
    if image.save
      render :text => "Yippee\n"      
    else
      render :text => image.errors.inspect
    end
  end
  
  def destroy
    
  end
end
