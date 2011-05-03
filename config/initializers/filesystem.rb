# Initialize required directories 
required_directories = []
required_directories << File.join(Rails.root, 'tmp', 'images')
required_directories << File.join(Rails.root, 'public', 'image-cache')
required_directories.each { |d| FileUtils.mkdir(d) unless File.directory? d }
