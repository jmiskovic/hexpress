#!/usr/bin/python
import os
import subprocess
import sys
import re

# files of interest
sources = []
media = set()

media.add('Ubuntu-B.ttf')

for directory, dirnames, filenames in os.walk('.'):
  for filename in filenames:
    name, extension = os.path.splitext(filename)
    if extension[1:] == 'lua':
      localPath  = os.path.join(directory, filename)
      sources.append(localPath)
      # scan script files for references to media files
      with open(localPath, 'r') as textfile:
        filetext = textfile.read()
        matches = re.findall(r'["\']patches/.*?/.*?\.[\w]{3}["\']', filetext)
        for m in matches:
          media.add(m[1:-1])

media = list(media)
# sort lists for better overview in console output
media.sort()
sources.sort()

pathlist = ' '.join(sources + media)

try:
  os.remove('game.love')
except:
  pass
status, output = subprocess.getstatusoutput('zip game.love ' + pathlist)
print(output)
print('Created game.love with size %1.2f Mb' % (os.path.getsize('./game.love') * 1E-6))
