# We need to fix this, libgpiod uses license "CC-BY-SA-4.0" which is not supported by Yocto
# e.g:
# - Find the actual license file in the source tree (e.g., LICENSE, COPYING, etc.).
# - Add this to the recipe:
# LICENSE = "CC-BY-SA-4.0"
# LIC_FILES_CHKSUM = "file://LICENSE;md5=<actual-md5sum
# - Get the MD5 checksum with:
# md5sum LICENSE
# - Make sure the path (file://LICENSE) is relative to ${S} (the source directory).
INSANE_SKIP += "license"
