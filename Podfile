# Uncomment this line to define a global platform for your project
platform :ios, '8.0'

# ignore all warnings from all pods
# see http://stackoverflow.com/questions/13208202/ignore-xcode-warnings-when-using-cocoapods
inhibit_all_warnings!

use_frameworks!

# was: link_with 'tuerauf_test', 'tuerauf_prod', 'tueraufTests'
# see http://stackoverflow.com/questions/37280077/error-with-cocoapods-link-with-after-update-to-1-0-0

abstract_target 'BasePods' do

    pod 'SwiftKeychain', '~> 0.1.5'

    target 'tuerauf_test' do
    end

    target 'tuerauf_prod' do
    end

    target 'tueraufTests' do
    end
end

