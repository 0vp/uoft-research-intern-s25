#!/bin/bash

echo "🔨 Building updated BER test program..."

# Compile the program
gcc -o ber_test ber_test.c -lm

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
else
    echo "❌ Build failed!"
    exit 1
fi
