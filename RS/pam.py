from slicer import Slicer

class PAM:
    def __init__(self, n=4, symbol_separation=48):
        self.n = n
        self.symbol_separation = symbol_separation
        self.levels = self._generate_levels()
        self.symbol_to_level_map = {i: self.levels[i] for i in range(n)}
        
    def _generate_levels(self):
        """Generate symmetric PAM levels around 0 with peak power normalization"""
        # Peak power normalization: all PAM schemes have same peak voltage
        # 2-PAM: +1/-1, 4-PAM: +1, +1/3, -1/3, -1, 8-PAM: -1, -5/7, -3/7, -1/7, +1/7, +3/7, +5/7, +1
        
        levels = []
        for i in range(self.n):
            # Generate normalized levels with peak = ±1
            normalized_level = (2 * i - (self.n - 1)) / (self.n - 1)
            # Scale by symbol separation
            level = normalized_level * self.symbol_separation
            levels.append(level)
        return levels
    
    def modulate(self, symbols):
        """Convert symbols to PAM levels"""
        return [self.symbol_to_level_map.get(symbol, 0) for symbol in symbols]
    
    def demodulate(self, levels):
        """Convert PAM levels back to symbols"""
        return Slicer.hard_slicer(levels, self.symbol_separation, self.n)
    
    def get_level(self, symbol):
        """Get PAM level for a single symbol"""
        return self.symbol_to_level_map.get(symbol, 0) 

if __name__ == "__main__":
    pam = PAM(n=6, symbol_separation=48)
    print(pam.modulate([0, 1, 2, 3, 4, 5, 6, 7, 8]))
    print(pam.demodulate([0, 1, 2, 3, 4, 5, 6, 7, 8]))