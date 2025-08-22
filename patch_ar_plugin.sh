#!/bin/bash

# Create a backup of the original build.gradle
cp /home/manudev/.pub-cache/hosted/pub.dev/ar_flutter_plugin-0.7.3/android/build.gradle /home/manudev/.pub-cache/hosted/pub.dev/ar_flutter_plugin-0.7.3/android/build.gradle.bak

# Apply the patch
patch -p1 -d /home/manudev/.pub-cache/hosted/pub.dev/ar_flutter_plugin-0.7.3/android/ < ar_flutter_plugin_fix.patch

echo "Patch applied successfully!"
echo "Please run 'flutter clean' and then try building your app again."
