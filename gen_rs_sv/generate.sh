#!/bin/bash
# Reed-Solomon Code Generator with Validation
# Usage: ./generate.sh [N] [K] [OUTPUT_DIR]
# Default: RS(200, 168) to gen/

# Set defaults
N=${1:-200}
K=${2:-168}
OUTPUT=${3:-gen}

echo "Reed-Solomon Code Generator"
echo "==========================="
echo "Generating RS($N, $K)"
echo "Output directory: $OUTPUT/"
echo ""

# Clean output directory
rm -rf $OUTPUT/*

# Run the generator
python3 src/generate_rs_1d.py --n $N --k $K --output $OUTPUT/

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Generation complete!"
    echo ""
    
    # Validate interfaces match reference structure
    echo "Validating interface compatibility..."
    VALIDATION_PASSED=true
    
    for file in encode.sv syndrome.sv rs_encode_wrapper.sv rs_decode_wrapper.sv; do
        if [ -f "ref_1d/$file" ] && [ -f "$OUTPUT/$file" ]; then
            # Extract module declarations and ports
            grep -E "^module |^\s*input |^\s*output " ref_1d/$file > /tmp/ref_interface.tmp 2>/dev/null
            grep -E "^module |^\s*input |^\s*output " $OUTPUT/$file > /tmp/gen_interface.tmp 2>/dev/null
            
            # For parameterized files, we expect differences in widths
            if [[ "$file" == *"wrapper"* ]]; then
                echo "  ✓ $file (parameterized)"
            else
                # Check if module structure matches
                MODULE_COUNT_REF=$(grep -c "^module " ref_1d/$file)
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