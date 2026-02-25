# Enable RDP support in Weston and add freerdp dependency
PACKAGECONFIG:append = " rdp"
DEPENDS:append = " freerdp"
