#!/usr/bin/env ruby
# Regenerates app/KanjiCrossword.xcodeproj. Run from the repository root:
#   gem install xcodeproj && ruby scripts/generate_xcodeproj.rb
require 'xcodeproj'
require 'fileutils'

root = File.expand_path('..', __dir__)
path = File.join(root, 'app', 'KanjiCrossword.xcodeproj')
FileUtils.rm_rf(path)
project = Xcodeproj::Project.new(path)
project.root_object.development_region = 'ja'
project.root_object.known_regions = %w[ja en Base]

group = project.main_group.new_group('KanjiCrossword', 'KanjiCrossword')
target = project.new_target(:application, 'KanjiCrossword', :ios, '18.0')

target.add_file_references([group.new_file('KanjiCrosswordApp.swift')])
resources = [
  group.new_file('Assets.xcassets'),
  group.new_file('PrivacyInfo.xcprivacy'),
  project.main_group.new_file('../content/puzzles-v2.json')
]
target.resources_build_phase.tap { |phase| resources.each { |f| phase.add_file_reference(f) } }
group.new_file('Info.plist')
project.main_group.new_file('../storekit/Products.storekit')

# Local package dependency (ui pulls in runtime and the iOS 18 shell).
ref = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
ref.relative_path = '../ui'
project.root_object.package_references << ref
dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
dep.product_name = 'KanjiCrosswordUI'
dep.package = ref if dep.respond_to?(:package=)
target.package_product_dependencies << dep
build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
build_file.product_ref = dep
target.frameworks_build_phase.files << build_file

settings = {
  'PRODUCT_BUNDLE_IDENTIFIER' => 'com.gooduse.kanjicrossword',
  'PRODUCT_NAME' => 'KanjiCrossword',
  'MARKETING_VERSION' => '1.0',
  'CURRENT_PROJECT_VERSION' => '1',
  'GENERATE_INFOPLIST_FILE' => 'YES',
  'INFOPLIST_FILE' => 'KanjiCrossword/Info.plist',
  'ASSETCATALOG_COMPILER_APPICON_NAME' => 'AppIcon',
  'ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME' => 'AccentColor',
  'SWIFT_VERSION' => '6.0',
  'IPHONEOS_DEPLOYMENT_TARGET' => '18.0',
  'TARGETED_DEVICE_FAMILY' => '1,2',
  'SUPPORTS_MACCATALYST' => 'NO',
  'SDKROOT' => 'iphoneos',
  'CODE_SIGN_STYLE' => 'Automatic',
  'DEVELOPMENT_TEAM' => '49SQ3XQ68Q',
  'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/Frameworks'
}
target.build_configurations.each { |c| c.build_settings.merge!(settings) }

project.save

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(target)
scheme.set_launch_target(target)
scheme.launch_action.build_configuration = 'Debug'
scheme.archive_action.build_configuration = 'Release'
scheme.save_as(path, 'KanjiCrossword', true)

# Use the local StoreKit configuration for Xcode runs.
scheme_path = File.join(path, 'xcshareddata', 'xcschemes', 'KanjiCrossword.xcscheme')
xml = File.read(scheme_path)
xml.sub!(%r{(<LaunchAction\b[^>]*>)}, "\\1\n      <StoreKitConfigurationFileReference\n         identifier = \"../../storekit/Products.storekit\">\n      </StoreKitConfigurationFileReference>") or abort 'LaunchAction not found'
File.write(scheme_path, xml)
