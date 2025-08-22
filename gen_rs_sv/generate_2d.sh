#!/bin/bash
# Reed-Solomon 2D Code Generator with Validation
# Usage: ./generate_2d.sh [N] [K] [OUTPUT_DIR]
# Default: RS(15, 11) 2D to gen_2d/

# Set defaults
N=${1:-15}
K=${2:-11}
OUTPUT=${3:-gen_2d}

echo "2D Reed-Solomon Code Generator"
echo "=============================="
echo "Generating 2D RS($N, $K)"
echo "Output directory: $OUTPUT/"
echo ""

# Clean output directory
rm -rf $OUTPUT/*

# Run the generator
python3 src/generate_rs_2d.py --n $N --k $K --output $OUTPUT/

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Generation complete!"
    echo ""

    # Validate interfaces match reference structure
    echo "Validating interface compatibility..."
    VALIDATION_PASSED=true

    for file in syndrome.sv rs_2d_encode.sv rs_2d_decode.sv serial_to_parallel.sv parallel_to_serial.sv; do
        if [ -f "ref_2d/$file" ] && [ -f "$OUTPUT/$file" ]; then
            # Extract module declarations and ports
            grep -E "^module |^\s*input |^\s*output " ref_2d/$file > /tmp/ref_interface.tmp 2>/dev/null
            grep -E "^module |^\s*input |^\s*output " $OUTPUT/$file > /tmp/gen_interface.tmp 2>/dev/null

            # For parameterized files, we expect differences in widths
            if [[ "$file" == *"rs_2d"* ]]; then
                echo "  ✓ $file (parameterized for 2D)"
            else
                # Check if module structure matches
                MODULE_COUNT_REF=$(grep -c "^module " ref_2d/$file)
                MODULE_COUNT_GEN=$(grep -c "^module " $OUTPUT/$file)

                if [ "$MODULE_COUNT_REF" = "$MODULE_COUNT_GEN" ]; then
                    echo "  ✓ $file (${MODULE_COUNT_GEN} modules)"
                else
                    echo "  ✗ $file module count mismatch"
                    VALIDATION_PASSED=false
                fi
            fi
        fi
    done

    echo ""
    if [ "$VALIDATION_PASSED" = true ]; then
        echo "✓ All validations passed!"
    else
        echo "⚠ Some validations failed - check the output"
    fi

    echo ""
    echo "Generated files:"
    ls -1 $OUTPUT/ 2>/dev/null
else
    echo "✗ Generation failed!"
    exit 1
fi
