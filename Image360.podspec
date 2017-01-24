Pod::Spec.new do |s|

  s.name         = "Image360"
  s.version      = "0.1.0"
  s.summary      = "Special controls to display 360° panoramic images."
  s.homepage     = "https://github.com/Ssimboss/Image360"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Andrew Simvolokov" => "ssimboss@gmail.com" }
  s.social_media_url   = "https://vk.com/simbos"
  s.platform     = :ios
  s.source       = { :git => "https://github.com/Ssimboss/Image360.git", :tag => s.version }
  s.source_files  = "Image360/**/*.swift"
  s.resources = "Image360/**/*.{jpg, glsl}"
  s.frameworks = "UIKit", "GLKit"

end
