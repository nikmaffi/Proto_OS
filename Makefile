ASM=nasm

SRC_DIR=src
BUILD_DIR=build

# This rule put the binary file into the image ad pad it with 0s until the size of the image is 1.44 MB
$(BUILD_DIR)/main_floppy.img: $(BUILD_DIR)/main.bin
	cp $^ $@
	truncate -s 1440k $@

$(BUILD_DIR)/main.bin: $(SRC_DIR)/main.asm
	$(ASM) $^ -f bin -o $@

start:
	qemu-system-i386 -fda build/main_floppy.img
