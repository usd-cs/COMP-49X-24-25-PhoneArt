#!/bin/bash
SCHEME='COMP-49X-24-25-PhoneArt'
DESTINATION='platform=iOS Simulator,OS=18.1,name=iPhone 16'
xcodebuild -project COMP-49X-24-25-PhoneArt.xcodeproj -scheme $SCHEME -destination "$DESTINATION" test CODE_SIGNING_ALLOWED='NO'
killall "iOS Simulator" 2>/dev/null || true