Pod::Spec.new do |s|
  s.name = "StaticLibrary"
  s.version = "1.0.0"
  s.summary = "StaticLibrary"
  s.homepage = "https://github.com/fanlilinSaber/xcframework_study"
  s.license = { type: 'MIT', file: 'LICENSE' }
  s.authors = { "Fan Li Lin" => '824589131.com' }
  s.platform = :ios, "11.0"
  s.swift_versions = ["5.0"]
  s.frameworks = 'Foundation', 'UIKit'
  s.requires_arc = true
  s.source = { :git => 'https://github.com/fanlilinSaber/xcframework_study.git', :tag => "v#{s.version}" }

 s.swift_version = "5.0"
 s.default_subspec = 'XCFramework'
 s.subspec "Code" do |ss|
    ss.source_files = "StaticLibrary/StaticLibrary/*.{h,m,swift}"
 end
 
 s.subspec "XCFramework" do |ss|
      ss.vendored_frameworks = ["StaticLibrary/XCFramework/StaticLibrary.xcframework"]
      ss.source_files = "StaticLibrary/XCFramework/Headers/*"
  end
  
end