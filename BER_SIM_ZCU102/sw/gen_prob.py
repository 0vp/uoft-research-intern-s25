import numpy as np
import math

def snr_to_hex_block(snr_db_list):
    """
    Convert a list of SNR values (in dB) to hex block values.
    
    Args:
        snr_db_list: List of SNR values in dB
    
    Returns:
        List of hex values corresponding to the SNR ranges
    """
    BLOCK_SIZE = 64
    amps = np.arange(BLOCK_SIZE, dtype=np.float64)
    var_s = ((2**7 - 1)**2) / 3  # signal variance for ±127 NRZ
    
    hex_values = []
    
    for snr_db in snr_db_list:
        # Convert SNR from dB to linear scale
        snr_linear = 10**(snr_db / 10)
        
        # Calculate noise variance from SNR
        var_n = var_s / snr_linear
        
        # We need to find a probability distribution p such that:
        # var_n = 2 * sum(p * amps^2)
        # where p represents the PDF of |n| and sum(p) = 1
        
        # Use a more sophisticated approach based on the target variance
        # Start with a reasonable initial distribution
        target_var = var_n / 2  # Divide by 2 since we'll multiply by 2 later
        
        # Use binary search to find the right exponential parameter
        lambda_min = 1e-6
        lambda_max = 1.0
        tolerance = 1e-4
        max_iterations = 100
        
        best_lambda = 0.1
        best_error = float('inf')
        
        for iteration in range(max_iterations):
            lambda_param = (lambda_min + lambda_max) / 2
            
            # Create exponential distribution with better numerical stability
            log_unnormalized = -lambda_param * amps
            max_log = np.max(log_unnormalized)
            unnormalized_p = np.exp(log_unnormalized - max_log)  # Numerical stability
            
            # Ensure no zeros or NaNs
            unnormalized_p = np.maximum(unnormalized_p, 1e-15)
            p = unnormalized_p / np.sum(unnormalized_p)
            
            # Calculate resulting variance
            calculated_var = np.sum(p * amps**2)
            error = abs(calculated_var - target_var) / target_var
            
            if error < best_error:
                best_error = error
                best_lambda = lambda_param
            
            if error < tolerance:
                break
                
            # Adjust search range
            if calculated_var > target_var:
                lambda_min = lambda_param  # Need more decay
            else:
                lambda_max = lambda_param  # Need less decay
        
        # Use the best lambda found
        lambda_param = best_lambda
        log_unnormalized = -lambda_param * amps
        max_log = np.max(log_unnormalized)
        unnormalized_p = np.exp(log_unnormalized - max_log)
        unnormalized_p = np.maximum(unnormalized_p, 1e-15)
        p = unnormalized_p / np.sum(unnormalized_p)
        
        # Convert probabilities to cumulative distribution
        cumulative = np.cumsum(p)
        
        # Ensure cumulative is properly bounded
        cumulative = np.clip(cumulative, 0.0, 1.0)
        
        # Scale to 64-bit range and convert to thresholds
        # Use more careful handling to avoid overflow
        max_uint64 = np.float64(0xffffffffffffffff)
        scaled_values = cumulative * max_uint64
        
        # Convert to uint64 with bounds checking
        thr_block = np.clip(scaled_values, 0, max_uint64).astype(np.uint64)
        
        # Ensure monotonicity and proper boundary conditions
        for i in range(1, len(thr_block)):
            if thr_block[i] < thr_block[i-1]:
                thr_block[i] = thr_block[i-1]
        
        # Ensure the last value is the maximum
        thr_block[-1] = np.uint64(0xffffffffffffffff)
        
        # Add to hex values list
        hex_values.extend(thr_block)
    
    return hex_values

# Example usage:
if __name__ == "__main__":
    # Example SNR values in dB
    target_snr_list = [5, 6, 7, 8, 9, 10, 10.5, 11, 11.5, 12, 12.5, 13, 13.5, 13.6, 13.7, 13.8, 13.9, 14]  # Add more as needed
    
    print("Generating hex values for SNR ranges:")
    for i, snr in enumerate(target_snr_list):
        print(f"Block {i}: Target SNR = {snr:.2f} dB")
    
    hex_block = snr_to_hex_block(target_snr_list)
    
    print(f"\nGenerated hex values ({len(hex_block)} values):")
    print("hex_values = [")
    for i, hex_val in enumerate(hex_block):
        if i % 4 == 0 and i > 0:
            print()
        print(f"0x{hex_val:016x}", end="")
        if i < len(hex_block) - 1:
            print(",", end="")
    print("\n]")
    
    # Verification: Use the original script logic to check our results
    print("\nVerification (using original script logic):")
    BLOCK_SIZE = 64
    amps = np.arange(BLOCK_SIZE, dtype=np.float64)
    var_s = ((2**7 - 1)**2) / 3
    
    thr = np.array(hex_block, dtype=np.uint64)
    n_blocks = len(thr) // BLOCK_SIZE
    
    for b in range(n_blocks):
        start = b * BLOCK_SIZE
        stop = start + BLOCK_SIZE
        thr_block = thr[start:stop]
        
        # PDF of |n| (length 64)
        p = np.diff(np.hstack(([0], thr_block))) / 2.0**64
        
        var_n = 2 * np.sum(p * amps**2)
        snr_db = 10 * math.log10(var_s / var_n)
        
        print(f"Block {b:2d}: Calculated SNR ≈ {snr_db:6.2f} dB (Target: {target_snr_list[b]:6.2f} dB)")