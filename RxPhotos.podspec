Pod::Spec.new do |s|
  s.name         = "RxPhotos"
  s.version      = "1.0.0"
  s.summary      = "Helpful classes and extensions for the iOS Photos framework"
  s.description  = <<-DESC
Helpful classes and extensions for the iOS Photos framework
                   DESC
  s.homepage     = "https://github.com/rpassis/RxPhotos"
  s.license      = { :type => "MIT", :file => "LICENSE.md" }
  s.author       = { "Rogerio de Paula Assis" => "rogerio@fastmail.com" }
  s.swift_version = "4.2"
  s.ios.deployment_target = "8.0"
  # s.osx.deployment_target = "10.10"
  # s.tvos.deployment_target = "9.0"
  # s.watchos.deployment_target = "2.0"
  s.source       = { :git => "https://github.com/rpassis/RxPhotos.git", :tag => "#{s.version}" }
  # s.source_files = 'Source/Common/*.swift'
  s.ios.source_files = 'Source/iOS/*.swift'
  s.dependency   "RxSwift", "~> 4.4"
  s.dependency   "RxCocoa", "~> 4.4"
end
