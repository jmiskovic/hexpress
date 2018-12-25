#!/usr/bin/python
import os
import commands
import sys

def push(localPath):
  remotePath = os.path.join('/sdcard/hexpress', localPath)
  status, output = commands.getstatusoutput(' '.join(('adb push', localPath, remotePath)))
  print(output)

if len(sys.argv) < 2:
  # recursively find all lua files and push to device
  for directory, dirnames, filenames in os.walk('.'):
    for filename in filenames:
      name, extension = os.path.splitext(filename)
      if extension == '.lua':
        localPath  = os.path.join(directory, filename)
        push(localPath)
elif len(sys.argv) == 2:
  # push path (file or directory) to device
  push(sys.argv[1])