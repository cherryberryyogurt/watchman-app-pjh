require 'yaml'

# Fetch flutter version info from yaml file
pubspec = YAML.load_file(File.join('..', 'pubspec.yaml'))
flutter_vers = pubspec['dependencies']['flutter']['sdk']
version = '0.0.1'

is_library_plugin = false
unless pubspec['flutter'].nil?
  is_library_plugin = pubspec['flutter']['plugin']['platforms']['ios'] != nil
end

Pod::Spec.new do |s|
  s.name             = 'integration_test'
  s.version          = version
  s.summary          = 'Integration test support for Flutter apps'
  s.description      = <<-DESC
Depends on the integration_test package from the Flutter SDK for integration testing.
                       DESC
  s.homepage         = 'https://flutter.dev'
  s.license          = { :type => 'BSD', :text => <<-LICENSE
Copyright 2014 The Flutter Authors. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.
    * Neither the name of Google Inc. nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

LICENSE
  }
  s.author           = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :http => 'https://github.com/flutter/flutter/tree/stable/packages/integration_test' }
  
  s.platform = :ios, '12.0'
  s.swift_version = '5.0'

  s.source_files = 'ios/**/*.{h,m,mm,swift}'
  s.public_header_files = 'ios/**/*.h'
  
  s.dependency 'Flutter'
  
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.resource_bundles = {}
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  
  # This creates a dummy source file for CocoaPods to compile
  s.prepare_command = <<-CMD
    mkdir -p ios/Sources/integration_test
    echo "// Dummy source file to satisfy CocoaPods" > ios/Sources/integration_test/dummy.m
    mkdir -p ios/Sources/integration_test/include
    echo "#import <Flutter/Flutter.h>" > ios/Sources/integration_test/include/integration_test.h
  CMD
end 