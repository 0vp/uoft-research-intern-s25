# Makefile for BER Simulation Tool
# Clean and simple build for ZCU102

CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=gnu99 -D_POSIX_C_SOURCE=199309L -lm
TARGET = ber_test
SOURCES = ber_test.c

# Default target
all: $(TARGET)

# Build the program
$(TARGET): $(SOURCES)
	$(CC) $(CFLAGS) -o $@ $^
	@echo "✅ Build complete: $(TARGET)"

# Clean build artifacts
clean:
	rm -f $(TARGET)
	@echo "Clean complete"

# Show help
help:
	@echo "Available targets:"
	@echo "  all     - Build the program"
	@echo "  clean   - Remove build artifacts"
	@echo "  help    - Show this help"

.PHONY: all clean help
