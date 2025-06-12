do_configure:prepend(){
	export PYTHON="${B}/../recipe-sysroot-native/usr/bin/python3-native/python3"
	export PYTHON_CONFIG="${B}/../recipe-sysroot-native/usr/bin/python3-config"
}