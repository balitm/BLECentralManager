#
# Be sure to run `pod lib lint BLECentralManager.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'BLECentralManager'
  s.version          = '0.1.1'
  s.summary          = 'A Bluetooth 4 central framework.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
BLECentralManager framework simplifies Bluetooth 4 (Low Energy) usage for central devices. The user of the framework have
to define a structure of expected services and characteristics and implement characteristic handler/delegate classes. The framework handles
- Searching and filtering peripherals.
- Connect to peripherals.
- Ask requested services and requested characteristics of them.
                       DESC

  s.homepage         = 'https://github.com/balitm/BLECentralManager'
  s.license          = { :type => 'BSD', :file => 'LICENSE.md' }
  s.author           = { 'Balázs Kilvády' => 'bkilvady@gmail.com' }
  s.source           = { :git => 'https://github.com/balitm/BLECentralManager.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.11'

  s.default_subspecs = 'ObjC'
  s.preserve_path = 'BLECentralManager/BLECentralManager.modulemap'
  s.module_map = 'BLECentralManager/BLECentralManager.modulemap'
 
  s.subspec 'ObjC' do |ss|
    ss.source_files = 'BLECentralManager/Classes/ObjC/*'
    ss.public_header_files = 'BLECentralManager/Classes/ObjC/BLEC*.h'
  end

  s.subspec 'Swift' do |ss|
    ss.source_files = 'BLECentralManager/Classes/Swift/*'
  end

end
