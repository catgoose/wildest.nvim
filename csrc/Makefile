CC ?= cc
CFLAGS = -O3 -Wall -Wextra -pedantic -shared -fPIC -s
TARGET = ../lua/wildest/fuzzy.so

.PHONY: all clean

all: $(TARGET)

$(TARGET): fuzzy.c fuzzy.h
	$(CC) $(CFLAGS) -o $(TARGET) fuzzy.c

clean:
	rm -f $(TARGET)
