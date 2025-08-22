class Slicer:
     @staticmethod
     def hard_slicer(symbols, symbol_separation=48, n_levels=4):
        """
        hard slicer for n-PAM symbols - hard_slicer @ slicer.sv
        Supports 4-PAM, 6-PAM, 8-PAM, etc.
        """
        
        # Generate constellation points dynamically with peak power normalization
        # Peak power normalization: all PAM schemes have same peak voltage
        constellation = []
        for i in range(n_levels):
            # Generate normalized levels with peak = ±1, then scale by symbol_separation
            normalized_level = (2 * i - (n_levels - 1)) / (n_levels - 1)
            level = normalized_level * symbol_separation
            constellation.append(level)
    
        decisions = []
        
        for symbol in symbols:
            # calculate squared distances
            distances_squared = [(symbol - point) ** 2 for point in constellation]
            
            # find minimum distance index - this gives us the original symbol
            min_distance_idx = distances_squared.index(min(distances_squared))
            decisions.append(min_distance_idx)
        
        return decisions