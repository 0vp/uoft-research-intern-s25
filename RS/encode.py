class GrayCode:
    @staticmethod
    def _get_gray_mapping(n_levels):
        """Generate gray code mapping for given number of PAM levels"""
        if n_levels == 4:
            # For 4-PAM, we need 2 bits per symbol (log2(4) = 2)
            # Current mapping for 4-PAM:
            gray_map = {
                (0, 0): (0,),  # 00 -> symbol 0
                (0, 1): (1,),  # 01 -> symbol 1
                (1, 0): (3,),  # 10 -> symbol 3 (11)
                (1, 1): (2,)   # 11 -> symbol 2 (10)
            }

            gray_map_inv = {
                (0,): (0, 0),  # symbol 0 -> 00
                (1,): (0, 1),  # symbol 1 -> 01
                (2,): (1, 1),  # symbol 2 -> 11
                (3,): (1, 0)   # symbol 3 -> 10
            }
            
            return gray_map, gray_map_inv
            
        elif n_levels == 6:
            # For 6-PAM, we use 5:2 block encoding - 5 bits map to 2 symbols
            # User-provided lookup table mapping
            gray_map = {
                (0, 0, 0, 0, 0): (0, 0), 
                (0, 0, 0, 0, 1): (1, 0), 
                (0, 0, 0, 1, 1): (2, 0), 
                (0, 1, 0, 1, 1): (3, 0),
                (0, 1, 0, 0, 1): (4, 0), 
                (0, 1, 0, 0, 0): (5, 0), 
                (0, 0, 1, 0, 0): (0, 1), 
                (0, 0, 0, 1, 0): (1, 1),
                (0, 1, 0, 1, 0): (2, 1), 
                (0, 1, 1, 0, 0): (3, 1), 
                (0, 0, 1, 0, 1): (0, 2), 
                (0, 0, 1, 1, 1): (1, 2),
                (0, 0, 1, 1, 0): (2, 2), 
                (0, 1, 1, 1, 0): (3, 2), 
                (0, 1, 1, 1, 1): (4, 2), 
                (0, 1, 1, 0, 1): (5, 2),
                (1, 0, 1, 0, 1): (0, 3), 
                (1, 0, 1, 1, 1): (1, 3), 
                (1, 0, 1, 1, 0): (2, 3), 
                (1, 1, 1, 1, 0): (3, 3),
                (1, 1, 1, 1, 1): (4, 3), 
                (1, 1, 1, 0, 1): (5, 3), 
                (1, 0, 1, 0, 0): (0, 4), 
                (1, 0, 0, 1, 0): (1, 4),
                (1, 1, 0, 1, 0): (2, 4), 
                (1, 1, 1, 0, 0): (3, 4), 
                (1, 0, 0, 0, 0): (0, 5), 
                (1, 0, 0, 0, 1): (1, 5),
                (1, 0, 0, 1, 1): (2, 5), 
                (1, 1, 0, 1, 1): (3, 5), 
                (1, 1, 0, 0, 1): (4, 5), 
                (1, 1, 0, 0, 0): (5, 5)
            }

            gray_map_inv = {
                (0, 0): (0, 0, 0, 0, 0), 
                (1, 0): (0, 0, 0, 0, 1), 
                (2, 0): (0, 0, 0, 1, 1), 
                (3, 0): (0, 1, 0, 1, 1),
                (4, 0): (0, 1, 0, 0, 1), 
                (5, 0): (0, 1, 0, 0, 0), 
                (0, 1): (0, 0, 1, 0, 0), 
                (1, 1): (0, 0, 0, 1, 0),
                (2, 1): (0, 1, 0, 1, 0), 
                (3, 1): (0, 1, 1, 0, 0), 
                (0, 2): (0, 0, 1, 0, 1), 
                (1, 2): (0, 0, 1, 1, 1),
                (2, 2): (0, 0, 1, 1, 0), 
                (3, 2): (0, 1, 1, 1, 0), 
                (4, 2): (0, 1, 1, 1, 1), 
                (5, 2): (0, 1, 1, 0, 1),
                (0, 3): (1, 0, 1, 0, 1), 
                (1, 3): (1, 0, 1, 1, 1), 
                (2, 3): (1, 0, 1, 1, 0), 
                (3, 3): (1, 1, 1, 1, 0),
                (4, 3): (1, 1, 1, 1, 1), 
                (5, 3): (1, 1, 1, 0, 1), 
                (0, 4): (1, 0, 1, 0, 0), 
                (1, 4): (1, 0, 0, 1, 0),
                (2, 4): (1, 1, 0, 1, 0), 
                (3, 4): (1, 1, 1, 0, 0), 
                (0, 5): (1, 0, 0, 0, 0), 
                (1, 5): (1, 0, 0, 0, 1),
                (2, 5): (1, 0, 0, 1, 1), 
                (3, 5): (1, 1, 0, 1, 1), 
                (4, 5): (1, 1, 0, 0, 1), 
                (5, 5): (1, 1, 0, 0, 0)
            }
            
            return gray_map, gray_map_inv
            
        elif n_levels == 8:
            # For 8-PAM, we need 3 bits per symbol (log2(8) = 3)
            # Standard binary-reflected Gray code for 8 levels
            gray_map = {
                (0, 0, 0): (0,),  # 000 -> symbol 0
                (0, 0, 1): (1,),  # 001 -> symbol 1
                (0, 1, 1): (2,),  # 011 -> symbol 2
                (0, 1, 0): (3,),  # 010 -> symbol 3
                (1, 1, 0): (4,),  # 110 -> symbol 4
                (1, 1, 1): (5,),  # 111 -> symbol 5
                (1, 0, 1): (6,),  # 101 -> symbol 6
                (1, 0, 0): (7,)   # 100 -> symbol 7
            }

            gray_map_inv = {
                (0,): (0, 0, 0),  # symbol 0 -> 000
                (1,): (0, 0, 1),  # symbol 1 -> 001
                (2,): (0, 1, 1),  # symbol 2 -> 011
                (3,): (0, 1, 0),  # symbol 3 -> 010
                (4,): (1, 1, 0),  # symbol 4 -> 110
                (5,): (1, 1, 1),  # symbol 5 -> 111
                (6,): (1, 0, 1),  # symbol 6 -> 101
                (7,): (1, 0, 0)   # symbol 7 -> 100
            }
            
            return gray_map, gray_map_inv
        else:
            raise NotImplementedError(f"Gray coding for {n_levels}-PAM is not implemented yet. Supported: 4, 6, 8-PAM.")

    @staticmethod
    def gray_encode(bits, n_levels=4):
        """
        apply gray encoding to the bits - grey_code.sv
        
        Args:
            bits: list of bits to encode
            n_levels: number of PAM levels (default 4)
        """
        gray_map, _ = GrayCode._get_gray_mapping(n_levels)

        if n_levels == 6:
            # Use efficient 5:2 block encoding for 6-PAM
            # Pad bits to multiple of 5
            padded_bits = bits[:]
            while len(padded_bits) % 5 != 0:
                padded_bits.append(0)
            
            gray_symbols = []
            for i in range(0, len(padded_bits), 5):
                block_bits = tuple(padded_bits[i:i+5])
                if block_bits in gray_map:
                    symbol_tuple = gray_map[block_bits]  # Returns (x, y) for 6-PAM
                    gray_symbols.append(symbol_tuple[0])  # Add x symbol
                    gray_symbols.append(symbol_tuple[1])  # Add y symbol
                else:
                    # Fallback for invalid bit patterns
                    gray_symbols.append(0)
                    gray_symbols.append(0)
            
            return gray_symbols

        # Standard encoding for 4-PAM and 8-PAM
        # Determine bits per symbol based on PAM level
        if n_levels == 4:
            bits_per_symbol = 2
        elif n_levels == 8:
            bits_per_symbol = 3
        else:
            raise NotImplementedError(f"Bits per symbol not defined for {n_levels}-PAM")

        # Pad with zeros if not enough bits
        while len(bits) % bits_per_symbol != 0:
            bits = bits + [0]
        
        gray_symbols = []
        for i in range(0, len(bits), bits_per_symbol):
            bit_tuple = tuple(bits[i:i+bits_per_symbol])
            symbol_tuple = gray_map[bit_tuple]  # Returns (symbol,) for 4-PAM and 8-PAM
            gray_symbols.append(symbol_tuple[0])  # Extract single symbol from tuple
        
        return gray_symbols
    
    @staticmethod
    def gray_decode(gray_symbols, n_levels=4, expected_bit_length=None):
        """
        decode gray encoded symbols back to bits
        
        Args:
            gray_symbols: list of gray encoded symbols
            n_levels: number of PAM levels (default 4)
            expected_bit_length: expected length of decoded bits (for 6-PAM padding fix)
        """
        _, gray_map_inv = GrayCode._get_gray_mapping(n_levels)
        
        if n_levels == 6:
            # Use efficient 5:2 block decoding for 6-PAM
            # Ensure we have multiple of 2 symbols
            padded_symbols = gray_symbols[:]
            while len(padded_symbols) % 2 != 0:
                padded_symbols.append(0)
            
            bits = []
            for i in range(0, len(padded_symbols), 2):
                # Clamp symbols to valid range
                x = max(0, min(5, int(padded_symbols[i])))
                y = max(0, min(5, int(padded_symbols[i+1])))
                symbol_pair = (x, y)  # 6-PAM uses 2-element tuples as keys
                
                if symbol_pair in gray_map_inv:
                    bit_tuple = gray_map_inv[symbol_pair]
                    bits.extend(bit_tuple)
                else:
                    # Fallback for invalid symbol combinations
                    bits.extend([0, 0, 0, 0, 0])
            
            # Fix padding issue: if expected_bit_length is provided, trim to that length
            if expected_bit_length is not None and len(bits) > expected_bit_length:
                bits = bits[:expected_bit_length]
            
            return bits
        
        # Standard decoding for 4-PAM and 8-PAM
        bits = []
        for symbol in gray_symbols:
            symbol_tuple = (symbol,)  # 4-PAM and 8-PAM use single-element tuples as keys
            if symbol_tuple in gray_map_inv:
                bit_tuple = gray_map_inv[symbol_tuple]
                bits.extend(bit_tuple)
            else:
                # Handle invalid symbols by mapping to symbol 0
                symbol_tuple = (0,)
                if symbol_tuple in gray_map_inv:
                    bit_tuple = gray_map_inv[symbol_tuple]
                    bits.extend(bit_tuple)
                else:
                    # Fallback - should not happen for valid PAM levels
                    if n_levels == 4:
                        bits.extend([0, 0])
                    elif n_levels == 8:
                        bits.extend([0, 0, 0])
        
        return bits

class Binary:
    @staticmethod
    def bit_encode(data, bits_per_symbol=16):
        """convert RS symbols to bits"""
        encoded_bits = []
        for symbol in data:
            # convert each symbol to bits (MSB first)
            for bit_pos in range(bits_per_symbol - 1, -1, -1):
                bit = (symbol >> bit_pos) & 1
                encoded_bits.append(bit)
        return encoded_bits
    
    @staticmethod
    def bit_decode(encoded_bits, bits_per_symbol=16):
        """convert bits back to RS symbols"""
        # Pad bits to multiple of bits_per_symbol to prevent IndexError
        padded_bits = encoded_bits[:]
        while len(padded_bits) % bits_per_symbol != 0:
            padded_bits.append(0)
        
        decoded_data = []
        for i in range(0, len(padded_bits), bits_per_symbol):
            symbol = 0
            for bit_pos in range(bits_per_symbol):
                symbol = (symbol << 1) | padded_bits[i + bit_pos]
            decoded_data.append(symbol)
        return decoded_data