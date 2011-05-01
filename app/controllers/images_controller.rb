require 'tempfile'

class ImagesController < ApplicationController
  
  def update
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
