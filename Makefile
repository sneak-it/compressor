CC = clang

objects += src/compressor.o src/compressor_filter_user.o src/config.o src/bpf_load.o src/compressor_cache_user.o
objects += src/compressor_ratelimit_user.o src/compressor_cache_seed.o

libbpf_objects += libbpf/src/bpf.o libbpf/src/btf.o libbpf/src/libbpf_errno.o libbpf/src/libbpf_probes.o
libbpf_objects += libbpf/src/libbpf.o libbpf/src/netlink.o libbpf/src/nlattr.o libbpf/src/str_error.o

CFLAGS += -Ilibbpf/src -O2 -Wall -Werror
LDFLAGS += -lconfig -lpthread -lelf -lhiredis

all: compressor compressor_filter
compressor: libbpf $(objects)
	clang $(LDFLAGS) -o compressor $(libbpf_objects) $(objects)
compressor_filter: src/compressor_filter_kern.o
	clang -Wall -Wextra -O2 -emit-llvm -c src/compressor_filter_kern.c -o src/compressor_filter_kern.bc
	llc -march=bpf -filetype=obj src/compressor_filter_kern.bc -o src/compressor_filter_kern.o
libbpf:
	$(MAKE) -C libbpf/src
clean:
	$(MAKE) -C libbpf/src clean
	rm -f src/*.o src/*.bc
	rm -f compressor
install:
	mkdir -p /etc/compressor
	cp -n compressor.example.conf /etc/compressor/compressor.conf
	cp src/compressor_filter_kern.o /etc/compressor/compressor_filter_kern.o
	cp compressor /usr/bin/compressor
	cp -n systemd/compressor.service /etc/systemd/system/

.PHONY: libbpf all
.DEFAULT: all