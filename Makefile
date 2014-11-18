TOP=$(PWD)
TOOLCHAIN=$(TOP)/xtensa-lx106-elf

all: sdk_patch $(TOOLCHAIN)/lib/libhal.a $(TOOLCHAIN)/bin/xtensa-lx106-elf-gcc
	@echo
	@echo "Xtensa toolchain is built, to use it:"
	@echo
	@echo 'export PATH=$(TOOLCHAIN)/bin:$$PATH'
	@echo
	@echo "Espressif ESP8266 SDK is installed, additional blobs are installed into the toolchain"
	@echo

sdk_patch: sdk/lib/libpp.a

sdk/lib/libpp.a: esp_iot_sdk_v0.9.2/.dir FRM_ERR_PATCH.rar
	unrar x -o+ FRM_ERR_PATCH.rar
	cp FRM_ERR_PATCH/*.a $$(dirname $@)

FRM_ERR_PATCH.rar:
	wget --content-disposition "http://bbs.espressif.com/download/file.php?id=10"

esp_iot_sdk_v0.9.2/.dir: esp_iot_sdk_v0.9.2_14_10_24.zip
	unzip $^
	ln -s $$(dirname $@) sdk
	touch $@

esp_iot_sdk_v0.9.2_14_10_24.zip:
	wget --content-disposition "http://bbs.espressif.com/download/file.php?id=9"

$(TOOLCHAIN)/lib/libhal.a: $(TOOLCHAIN)/bin/xtensa-lx106-elf-gcc
	make -C lx106-hal -f ../Makefile libhal

libhal:
	autoreconf -i
	PATH=$(TOOLCHAIN)/bin:$(PATH) ./configure --host=xtensa-lx106-elf --prefix=$(TOOLCHAIN)
	PATH=$(TOOLCHAIN)/bin:$(PATH) make
	PATH=$(TOOLCHAIN)/bin:$(PATH) make install


$(TOOLCHAIN)/bin/xtensa-lx106-elf-gcc: crosstool-NG/ct-ng
	make -C crosstool-NG -f ../Makefile toolchain

toolchain: esp_iot_sdk_v0.9.2/.dir
	./ct-ng xtensa-lx106-elf
	sed -r -i.org s%CT_PREFIX_DIR=.*%CT_PREFIX_DIR="$(TOOLCHAIN)"% .config
	sed -r -i s%CT_INSTALL_DIR_RO=y%"#"CT_INSTALL_DIR_RO=y% .config
	echo CT_STATIC_TOOLCHAIN=y >> .config
	./ct-ng build
	@echo "Installing additional SDK headers"
	@cp -Rfv sdk/include/* $(TOOLCHAIN)/xtensa-lx106-elf/usr/include/
	@echo "Installing additional SDK blobs"
	@cp -Rfv sdk/lib/* $(TOOLCHAIN)/xtensa-lx106-elf/lib/

crosstool-NG/ct-ng: crosstool-NG/bootstrap
	make -C crosstool-NG -f ../Makefile ct-ng

ct-ng:
	./bootstrap
	./configure --prefix=`pwd`
	make MAKELEVEL=0
	make install MAKELEVEL=0

crosstool-NG/bootstrap:
	@echo "You cloned without --recursive, fetching submodules for you."
	git submodule update --init --recursive
