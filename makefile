booter.img	:	booter.BIN pic.bin
	cat booter.BIN pic.bin > booter.img 
	truncate -s 1474560 booter.img

pic.bin		:	pic.png
	packedpixels --bpp 2 --interleave 2 --padding 192 < pic.png > pic.bin

booter.BIN	:	booter.asm
	jwasm -bin -Fl=booter.lst booter.asm
	
clean	:	.SYMBOLIC
	rm -f *.obj *.lst *.err *.BIN *.img *.bin

run	:	.SYMBOLIC booter.img
	dosbox booter.img
	
install	:	.SYMBOLIC booter.img
	sudo dd if=booter.img of=/dev/sdh