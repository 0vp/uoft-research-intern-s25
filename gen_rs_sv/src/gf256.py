"""
Galois Field GF(2^8) operations for Reed-Solomon codes
Using primitive polynomial: x^8 + x^7 + x^2 + x + 1 (0x187)
"""

class GF256:
    """Galois Field GF(2^8) arithmetic operations"""
    
    # Primitive polynomial: x^8 + x^7 + x^2 + x + 1
    # This matches the reference implementation
    PRIMITIVE_POLY = 0x187
    
    def __init__(self):
        # Precompute log and antilog tables
        self.log_table = [0] * 256
        self.antilog_table = [0] * 512  # Extended for easier wraparound
        self._generate_tables()
    
    def _generate_tables(self):
        """Generate log and antilog tables for GF(256)"""
        # Generate antilog table (powers of alpha)
        val = 1
        for i in range(255):
            self.antilog_table[i] = val
            self.antilog_table[i + 255] = val  # Duplicate for wraparound
            self.log_table[val] = i
            # Multiply by alpha (which is 2)
            val = val << 1
            if val >= 256:
                val ^= self.PRIMITIVE_POLY
        
        # Special case for 0
        self.log_table[0] = 255  # Undefined, but use 255 by convention
    
    def mult(self, a: int, b: int) -> int:
        """Multiply two elements in GF(256)"""
        if a == 0 or b == 0:
            return 0
        log_sum = self.log_table[a] + self.log_table[b]
        return self.antilog_table[log_sum]
    
    def add(self, a: int, b: int) -> int:
        """Add two elements in GF(256) (same as XOR)"""
        return a ^ b
    
    def power(self, base: int, exp: int) -> int:
        """Compute base^exp in GF(256)"""
        if base == 0:
            return 0
        if exp == 0:
            return 1
        log_result = (self.log_table[base] * exp) % 255
        return self.antilog_table[log_result]
    
    def inverse(self, a: int) -> int:
        """Find multiplicative inverse in GF(256)"""
        if a == 0:
            return 0
        return self.antilog_table[255 - self.log_table[a]]
    
    def get_generator_polynomial(self, n_roots: int) -> list:
        """
        Generate the generator polynomial for RS code
        g(x) = (x - α^1)(x - α^2)...(x - α^n_roots)
        Returns list of coefficients [g0, g1, ..., g_n_roots]
        Uses narrow-sense BCH configuration (roots starting at α^1)
        """
        # Start with g(x) = 1
        poly = [1]
        
        for i in range(1, n_roots + 1):  # Start from 1 for narrow-sense
            # Multiply by (x - α^i)
            alpha_i = self.power(2, i)  # α = 2 is the primitive element
            new_poly = [0] * (len(poly) + 1)
            
            # x * poly
            for j in range(len(poly)):
                new_poly[j+1] = poly[j]
            
            # - α^i * poly
            for j in range(len(poly)):
                new_poly[j] = self.add(new_poly[j], self.mult(alpha_i, poly[j]))
            
            poly = new_poly
        
        return poly
    
    def get_xor_pattern(self, coeff: int, out_bit: int) -> list:
        """
        Get the XOR pattern for a specific output bit when multiplying by coeff
        Returns list of input bit indices that should be XORed
        """
        pattern = []
        for in_bit in range(8):
            test_val = 1 << in_bit
            result = self.mult(test_val, coeff)
            if result & (1 << out_bit):
                pattern.append(in_bit)
        return pattern