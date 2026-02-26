CC ?= cc
CFLAGS = -O3 -Wall -shared -fPIC
TARGET = ../lua/wildest/fuzzy.so

.PHONY: all clean

all: $(TARGET)

$(TARGET): fuzzy.c fuzzy.h
	$(CC) $(CFLAGS) -o $(TARGET) fuzzy.c

clean:
	rm -f $(TARGET)
