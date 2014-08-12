#!/bin/sh
if [ `command -v dir 2>&1` ]; then
  os='win32'
elif [ `command -v defaults 2>&1` ]; then
  os='macos'
else
  os='others'
fi
echo $os
