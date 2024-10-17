.PHONY: all clean test bit-a-bit-store run

bit-a-bit-store: bit-a-bit_store.s
	aarch64-linux-gnu-gcc -static $< -o $@

run: bit-a-bit-store
	qemu-aarch64 $<

clean:
	rm -f bit-a-bit-store
