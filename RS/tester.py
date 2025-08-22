"""
SNR Testing Framework for PAM/RS Performance Analysis
Usage: python tester.py [config_name]

This script runs comprehensive BER/SER vs SNR sweeps using binary search
and adaptive refinement for different:
- PAM levels (4, 6, 8)  
- Reed-Solomon codes
- Equalizer configurations
"""

import sys
import os
import json
import shutil
from datetime import datetime
import numpy as np

# Testing configurations
CONFIGS = {
    "final": {
        "description": "Binary search SNR sweep with adaptive refinement",
        "snr_start": 20.0,  # Starting SNR
        "snr_max": 35.0,    # Maximum SNR to test
        "min_points": 15,   # Minimum number of points to characterize the curve
        "max_points": 30,   # Maximum number of points to test
        "min_snr_gap": 0.005,  # Minimum gap between SNR points
        "ber_high": 0.11,   # Upper BER threshold for binary search (1%)
        "ber_low": 1e-5,    # Lower BER threshold for binary search
        "min_ber_gap": 0.3, # Minimum log10(BER) gap to stop refinement (0.3 means ~2x BER difference)
        "iterations": 4,
        "data_size": 5000000,
        "training_size": 1000,
        "mu": 0.000001,
        "pam_levels": [4, 6, 8],
        "rs_codes": [(69, 65), (102, 96)],
        "raw_mode": False,
        "continuous_mode": {
            "enabled": False,
            "max_bit_errors": 10,
            "max_data_symbols": 1000000,
            "chunk_size": 1000
        }
    },
    "high_snr": {
        "description": "High SNR sweep with binary search",
        "snr_start": 20.0,  # Starting SNR
        "snr_max": 32.0,    # Maximum SNR to test
        "min_points": 10,   # Minimum number of points to characterize the curve
        "max_points": 20,   # Maximum number of points to test
        "min_snr_gap": 0.01,  # Minimum gap between SNR points
        "ber_high": 0.11,   # Upper BER threshold for binary search (1%)
        "ber_low": 1e-5,    # Lower BER threshold for binary search
        "min_ber_gap": 0.5, # Minimum log10(BER) gap to stop refinement
        "iterations": 4,
        "data_size": 10000,
        "training_size": 1000,
        "mu": 0.000001,
        "pam_levels": [4, 6, 8],
        "rs_codes": [(69, 65), (102, 96)],
        "raw_mode": False,
        "continuous_mode": {
            "enabled": False,
            "max_bit_errors": 10,
            "max_data_symbols": 1000000,
            "chunk_size": 1000
        }
    },
    "continuous": {
        "description": "Continuous mode SNR sweep for efficient low-BER testing",
        "snr_start": 18.0,  # Starting SNR
        "snr_max": 30.0,    # Maximum SNR to test
        "snr_step": 0.5,    # SNR step size for linear sweep
        "iterations": 3,    # Fewer iterations since continuous mode is more efficient
        "data_size": 1000,  # Not used in continuous mode, but kept for compatibility
        "training_size": 1000,
        "mu": 0.000001,
        "pam_levels": [4, 6, 8],
        "rs_codes": [(69, 65), (102, 96)],
        "raw_mode": False,
        "continuous_mode": {
            "enabled": True,
            "max_bit_errors": 10,
            "max_data_symbols": 500000,
            "chunk_size": 1000
        }
    }
}

def clean_directories():
    """Clean the figs and logs directories"""
    dirs_to_clean = ['./figs', './logs']
    
    for dir_path in dirs_to_clean:
        if os.path.exists(dir_path):
            print(f"Cleaning {dir_path}...")
            shutil.rmtree(dir_path)
        os.makedirs(dir_path, exist_ok=True)
        print(f"Created clean {dir_path}")
    print()

def run_single_test(n, k, pam_level, snr_db, iteration, data_size=64, raw_mode=False, training_size=100, mu=0.00001, continuous_mode=None):
    """Run a single test by calling model.py via terminal"""
    import subprocess
    import re
    
    # Build command line arguments for model.py
    cmd = [
        sys.executable, "model.py",
        "--n", str(n),
        "--k", str(k),
        "--mu", str(mu),
        "--pam_levels", str(pam_level),
        "--snr_db", str(snr_db),
        "--data_size", str(data_size),
        "--training_size", str(training_size)
    ]
    
    # Add raw flag if needed
    if raw_mode:
        cmd.append("--raw")
    
    # Add continuous mode arguments if enabled
    if continuous_mode and continuous_mode.get('enabled', False):
        cmd.append("--continuous_mode")
        cmd.extend(["--max_bit_errors", str(continuous_mode.get('max_bit_errors', 10))])
        cmd.extend(["--max_data_symbols", str(continuous_mode.get('max_data_symbols', 1000000))])
        cmd.extend(["--chunk_size", str(continuous_mode.get('chunk_size', 1000))])
    
    try:
        # Run model.py via subprocess
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            # Parse output to extract BER and SER
            output = result.stdout
            
            # Look for BER and SER lines in the output
            ber_match = re.search(r'BER:\s*([\d.]+)', output)
            ser_match = re.search(r'SER:\s*([\d.]+)', output)
            
            if ber_match and ser_match:
                ber = float(ber_match.group(1))
                ser = float(ser_match.group(1))
                return {"ser": ser, "ber": ber, "success": True}
            else:
                print(f"Could not parse BER/SER from output: {output}")
                return {"ser": 1.0, "ber": 1.0, "success": False}
        else:
            print(f"model.py failed with return code {result.returncode}")
            print(f"stderr: {result.stderr}")
            return {"ser": 1.0, "ber": 1.0, "success": False}
            

    except Exception as e:
        print(f"Error running test: {e}")
        return {"ser": 1.0, "ber": 1.0, "success": False}

def run_linear_snr_sweep(n, k, pam_level, config, timestamp):
    """Run SNR sweep using linear progression for continuous mode with gap refinement"""
    raw_mode = config.get('raw_mode', False)
    
    if raw_mode:
        print(f"Testing {pam_level}-PAM RAW transmission (linear sweep)")
        log_filename = f"./logs/snr_sweep_{pam_level}PAM_RAW_{timestamp}.log"
    else:
        print(f"Testing {pam_level}-PAM with RS({n},{k}) (linear sweep)")
        log_filename = f"./logs/snr_sweep_{pam_level}PAM_RS{n}_{k}_{timestamp}.log"
    
    results = []
    
    def test_snr_point(snr):
        """Test a single SNR point and return statistics"""
        print(f"  SNR: {snr:6.3f} dB", end=" ")
        ser_values = []
        ber_values = []
        success_count = 0
        
        for iteration in range(config['iterations']):
            result = run_single_test(n, k, pam_level, snr, iteration,
                                   config['data_size'], raw_mode,
                                   config.get('training_size', 100),
                                   config.get('mu', 0.00001),
                                   config.get('continuous_mode'))
            
            if result['success']:
                ser_values.append(result['ser'])
                ber_values.append(result['ber'])
                success_count += 1
            
            print(".", end="", flush=True)
        
        # Calculate statistics
        if success_count > 0:
            ser_mean = sum(ser_values) / len(ser_values)
            ber_mean = sum(ber_values) / len(ber_values)
            
            if len(ser_values) > 1:
                ser_var = sum((x - ser_mean) ** 2 for x in ser_values) / (len(ser_values) - 1)
                ser_std = ser_var ** 0.5
                ber_var = sum((x - ber_mean) ** 2 for x in ber_values) / (len(ber_values) - 1)
                ber_std = ber_var ** 0.5
            else:
                ser_std = ber_std = 0.0
        else:
            ser_mean = ber_mean = 1.0
            ser_std = ber_std = 0.0
        
        result_data = {
            "snr_db": snr,
            "ser_mean": ser_mean,
            "ber_mean": ber_mean,
            "ser_std": ser_std,
            "ber_std": ber_std,
            "success_count": success_count,
            "total_iterations": config['iterations']
        }
        
        print(f" SER: {ser_mean:.6f}, BER: {ber_mean:.6f}")
        
        results.append(result_data)
        # Sort results after adding new point
        results.sort(key=lambda x: x['snr_db'])
        return result_data
    
    # Linear sweep from start to max with fixed step size
    print(f"\nPhase 1: Linear SNR sweep from {config['snr_start']} to {config['snr_max']} dB with {config['snr_step']} dB steps")
    print("Early stopping: Will stop after 2 consecutive SNR points with BER = 0 and SER = 0")
    
    current_snr = config['snr_start']
    consecutive_zero_errors = 0
    
    while current_snr <= config['snr_max']:
        result_data = test_snr_point(current_snr)
        
        # Check for early stopping condition: BER = 0 and SER = 0
        if result_data['ber_mean'] == 0.0 and result_data['ser_mean'] == 0.0:
            consecutive_zero_errors += 1
            print(f"    Zero errors detected ({consecutive_zero_errors}/2 consecutive)")
            
            # Stop if we've had 2 consecutive zero-error points
            if consecutive_zero_errors >= 2:
                print(f"    Early stopping: 2 consecutive SNR points with zero errors")
                break
        else:
            # Reset counter if we encounter non-zero errors
            consecutive_zero_errors = 0
        
        current_snr += config['snr_step']
    
    # Phase 2: Gap refinement
    print("\nPhase 2: BER gap refinement")
    target_ber_levels = [1e-1, 1e-2, 1e-3, 1e-4, 1e-5]
    min_ber_ratio = 5  # Maximum allowed ratio between adjacent BER points
    max_refinement_points = 10  # Maximum number of additional points to add
    min_snr_gap = config['snr_step'] / 4  # Minimum SNR gap between points
    
    def find_missing_ber_levels():
        """Find BER levels that need additional points"""
        missing_levels = []
        for target_ber in target_ber_levels:
            # Skip if target BER is too low (below our measurement capability)
            if any(r['ber_mean'] == 0 and r['snr_db'] < config['snr_max'] for r in results):
                lowest_measurable = min(r['ber_mean'] for r in results if r['ber_mean'] > 0)
                if target_ber < lowest_measurable:
                    continue
            
            # Check if we have a measurement close to this BER level
            found_close = False
            for result in results:
                if result['ber_mean'] > 0:  # Skip zero BER
                    ber_ratio = max(result['ber_mean'], target_ber) / min(result['ber_mean'], target_ber)
                    if ber_ratio <= 3:  # Within 3x of target
                        found_close = True
                        break
            
            if not found_close:
                missing_levels.append(target_ber)
        return missing_levels
    
    def find_large_ber_gaps():
        """Find gaps where BER ratio between adjacent points is too large"""
        gaps = []
        for i in range(len(results) - 1):
            ber1 = results[i]['ber_mean']
            ber2 = results[i + 1]['ber_mean']
            if ber1 > 0 and ber2 > 0:  # Only consider non-zero BER points
                ber_ratio = ber1 / ber2 if ber1 > ber2 else ber2 / ber1
                if ber_ratio > min_ber_ratio:
                    gaps.append((i, ber_ratio))
        return gaps
    
    refinement_count = 0
    while refinement_count < max_refinement_points:
        # First try to fill in missing BER levels
        missing_levels = find_missing_ber_levels()
        if missing_levels:
            print(f"\nMissing BER levels: {[f'{ber:.1e}' for ber in missing_levels]}")
            
            for target_ber in missing_levels:
                # Find bracketing points for binary search
                lower_point = None
                upper_point = None
                
                for result in results:
                    if result['ber_mean'] > target_ber:
                        if lower_point is None or result['ber_mean'] < lower_point['ber_mean']:
                            lower_point = result
                    elif result['ber_mean'] > 0 and result['ber_mean'] < target_ber:
                        if upper_point is None or result['ber_mean'] > upper_point['ber_mean']:
                            upper_point = result
                
                if lower_point and upper_point:
                    # Linear interpolation in log(BER) vs SNR space
                    log_ber_low = np.log10(lower_point['ber_mean'])
                    log_ber_high = np.log10(upper_point['ber_mean'])
                    log_ber_target = np.log10(target_ber)
                    
                    snr_low = lower_point['snr_db']
                    snr_high = upper_point['snr_db']
                    
                    # Interpolate
                    ratio = (log_ber_target - log_ber_low) / (log_ber_high - log_ber_low)
                    snr_estimate = snr_low + ratio * (snr_high - snr_low)
                    
                    # Check if we can insert here
                    can_insert = True
                    for result in results:
                        if abs(snr_estimate - result['snr_db']) < min_snr_gap:
                            can_insert = False
                            break
                    
                    if can_insert:
                        print(f"  Targeting BER {target_ber:.1e} at estimated SNR {snr_estimate:.3f} dB")
                        test_snr_point(snr_estimate)
                        refinement_count += 1
                        break  # Try one point at a time
        
        # Then look for large gaps between adjacent BER measurements
        if refinement_count < max_refinement_points:
            gaps = find_large_ber_gaps()
            if not gaps:
                print("\nNo large BER gaps found, refinement complete")
                break
            
            # Sort gaps by ratio size (largest first)
            gaps.sort(key=lambda x: x[1], reverse=True)
            largest_gap = gaps[0]
            i = largest_gap[0]
            
            # Calculate midpoint SNR
            snr_mid = (results[i]['snr_db'] + results[i + 1]['snr_db']) / 2
            
            # Check if we can insert here
            can_insert = True
            for result in results:
                if abs(snr_mid - result['snr_db']) < min_snr_gap:
                    can_insert = False
                    break
            
            if can_insert:
                print(f"\nFilling large BER gap (ratio: {largest_gap[1]:.1f}x) at SNR {snr_mid:.3f} dB")
                test_snr_point(snr_mid)
                refinement_count += 1
            else:
                print("\nNo valid insertion points found, refinement complete")
                break
        
        if refinement_count >= max_refinement_points:
            print(f"\nReached maximum refinement points ({max_refinement_points})")
            break
    
    print(f"\nCompleted linear sweep with refinement ({len(results)} total points)")
    
    # Save results
    log_data = {
        "timestamp": timestamp,
        "config": "linear_sweep_with_refinement",
        "pam_level": pam_level,
        "rs_code": [n, k] if not raw_mode else None,
        "raw_mode": raw_mode,
        "results": results,
        "metadata": {
            "description": config['description'],
            "data_size": config['data_size'],
            "total_iterations": config['iterations'],
            "linear_sweep_parameters": {
                "snr_start": config['snr_start'],
                "snr_max": config['snr_max'],
                "snr_step": config['snr_step'],
                "refinement": {
                    "target_ber_levels": target_ber_levels,
                    "min_ber_ratio": min_ber_ratio,
                    "max_refinement_points": max_refinement_points,
                    "min_snr_gap": min_snr_gap
                }
            }
        }
    }
    
    os.makedirs("./logs", exist_ok=True)
    with open(log_filename, 'w') as f:
        json.dump(log_data, f, indent=4)
    print(f"Results saved to {log_filename}")
    
    return results

def run_binary_search_sweep(n, k, pam_level, config, timestamp):
    """Run SNR sweep using binary search to find performance cliff"""
    raw_mode = config.get('raw_mode', False)
    
    if raw_mode:
        print(f"Testing {pam_level}-PAM RAW transmission (binary search)")
        log_filename = f"./logs/snr_sweep_{pam_level}PAM_RAW_{timestamp}.log"
    else:
        print(f"Testing {pam_level}-PAM with RS({n},{k}) (binary search)")
        log_filename = f"./logs/snr_sweep_{pam_level}PAM_RS{n}_{k}_{timestamp}.log"
    
    results = []
    
    def test_snr_point(snr):
        """Test a single SNR point and return statistics"""
        print(f"  SNR: {snr:6.3f} dB", end=" ")
        ser_values = []
        ber_values = []
        success_count = 0
        
        for iteration in range(config['iterations']):
            result = run_single_test(n, k, pam_level, snr, iteration,
                                   config['data_size'], raw_mode,
                                   config.get('training_size', 100),
                                   config.get('mu', 0.00001),
                                   config.get('continuous_mode'))
            
            if result['success']:
                ser_values.append(result['ser'])
                ber_values.append(result['ber'])
                success_count += 1
            
            print(".", end="", flush=True)
        
        # Calculate statistics
        if success_count > 0:
            ser_mean = sum(ser_values) / len(ser_values)
            ber_mean = sum(ber_values) / len(ber_values)
            
            if len(ser_values) > 1:
                ser_var = sum((x - ser_mean) ** 2 for x in ser_values) / (len(ser_values) - 1)
                ser_std = ser_var ** 0.5
                ber_var = sum((x - ber_mean) ** 2 for x in ber_values) / (len(ber_values) - 1)
                ber_std = ber_var ** 0.5
            else:
                ser_std = ber_std = 0.0
        else:
            ser_mean = ber_mean = 1.0
            ser_std = ber_std = 0.0
        
        result_data = {
            "snr_db": snr,
            "ser_mean": ser_mean,
            "ber_mean": ber_mean,
            "ser_std": ser_std,
            "ber_std": ber_std,
            "success_count": success_count,
            "total_iterations": config['iterations']
        }
        
        print(f" SER: {ser_mean:.6f}, BER: {ber_mean:.6f}")
        
        results.append(result_data)
        # Sort results after adding new point
        results.sort(key=lambda x: x['snr_db'])
        return result_data
    
    # Phase 1: Binary search to find performance cliff boundaries based on BER
    print("\nPhase 1: Binary search for performance cliff boundaries")
    
    # Test endpoints first
    test_snr_point(config['snr_start'])
    test_snr_point(config['snr_max'])
    
    # Initialize search boundaries
    left = config['snr_start']
    right = config['snr_max']
    
    # Binary search for upper boundary (where BER starts dropping below ber_high)
    print("\nSearching for upper cliff boundary (BER < {})...".format(config['ber_high']))
    while right - left > config['min_snr_gap']:
        mid = (left + right) / 2
        result = test_snr_point(mid)
        
        if result['ber_mean'] > config['ber_high']:
            left = mid
        else:
            right = mid
    
    upper_boundary = (left + right) / 2
    print(f"Upper boundary found at ~{upper_boundary:.3f} dB")
    # Test the actual boundary point if not already tested
    upper_result = test_snr_point(upper_boundary)
    if upper_result:
        print(f"Upper boundary BER: {upper_result['ber_mean']:.2e}")
    
    # Binary search for lower boundary (where BER drops below ber_low)
    left = upper_boundary
    right = config['snr_max']
    print("\nSearching for lower cliff boundary (BER < {})...".format(config['ber_low']))
    while right - left > config['min_snr_gap']:
        mid = (left + right) / 2
        result = test_snr_point(mid)
        
        if result['ber_mean'] > config['ber_low']:
            left = mid
        else:
            right = mid
    
    lower_boundary = (left + right) / 2
    print(f"Lower boundary found at ~{lower_boundary:.3f} dB")
    # Test the actual boundary point if not already tested
    lower_result = test_snr_point(lower_boundary)
    if lower_result:
        print(f"Lower boundary BER: {lower_result['ber_mean']:.2e}")
    
    # Phase 2: Adaptive refinement based on BER gaps
    print("\nPhase 2: Adaptive refinement based on BER gaps")
    cliff_width = lower_boundary - upper_boundary
    
    # Issue 5: Handle zero or negative cliff width
    if cliff_width <= config['min_snr_gap']:
        print(f"Warning: Cliff width {cliff_width:.4f} dB is too small (< {config['min_snr_gap']} dB)")
        print("Performance cliff is very narrow or not found. Adding a few points around the boundary.")
        
        # Use proportional offsets based on min_snr_gap
        search_radius = max(cliff_width, config['min_snr_gap']) * 2
        offsets = [-search_radius, -search_radius/2, search_radius/2, search_radius]
        
        for offset in offsets:
            snr_test = upper_boundary + offset
            if config['snr_start'] <= snr_test <= config['snr_max']:
                test_snr_point(snr_test)
    else:
        # Add initial even-spaced points within the cliff region only
        if len(results) < config['min_points']:
            # Count how many points we already have in the cliff region
            points_in_cliff = sum(1 for r in results if upper_boundary <= r['snr_db'] <= lower_boundary)
            n_additional = max(config['min_points'] - len(results), 3 - points_in_cliff)
            
            if n_additional > 0:
                step = cliff_width / (n_additional + 1)
                current_snr = upper_boundary + step
                for _ in range(n_additional):
                    if current_snr < lower_boundary:  # Stay within cliff region
                        test_snr_point(current_snr)
                    current_snr += step
        
        # Adaptive refinement loop - focus on BER distribution
        iteration_count = 0
        max_refinement_iterations = config['max_points'] - len(results)
        
        while len(results) < config['max_points'] and iteration_count < max_refinement_iterations:
            iteration_count += 1
            
            # Sort results by SNR to ensure proper ordering
            results.sort(key=lambda x: x['snr_db'])
            
            # Phase 2a: Check if we need targeted BER level sampling
            target_ber_levels = [1e-2, 1e-3, 1e-4,1e-5]
            missing_levels = []
            
            for target_ber in target_ber_levels:
                if config['ber_low'] <= target_ber <= config['ber_high']:
                    # Check if we have a measurement close to this BER level
                    found_close = False
                    for result in results:
                        if result['ber_mean'] > 0:  # Skip zero BER
                            ber_ratio = max(result['ber_mean'], target_ber) / min(result['ber_mean'], target_ber)
                            if ber_ratio <= 3:  # Within 3x of target
                                found_close = True
                                break
                    
                    if not found_close:
                        missing_levels.append(target_ber)
            
            # If we have missing BER levels, try to find SNR points for them
            added_targeted_point = False
            if missing_levels and len(results) >= 3:  # Need at least 3 points for interpolation
                print(f"\nMissing BER levels: {[f'{ber:.1e}' for ber in missing_levels[:2]]}")  # Show first 2
                
                for target_ber in missing_levels[:2]:  # Try to add 2 targeted points per iteration
                    # Find the two closest BER measurements
                    valid_results = [r for r in results if r['ber_mean'] > 0]
                    if len(valid_results) < 2:
                        continue
                    
                    # Find bracketing points
                    lower_point = None
                    upper_point = None
                    
                    for result in valid_results:
                        if result['ber_mean'] > target_ber:
                            if lower_point is None or result['ber_mean'] < lower_point['ber_mean']:
                                lower_point = result
                        elif result['ber_mean'] < target_ber:
                            if upper_point is None or result['ber_mean'] > upper_point['ber_mean']:
                                upper_point = result
                    
                    # If we have bracketing points, interpolate SNR
                    if lower_point and upper_point:
                        # Linear interpolation in log(BER) vs SNR space
                        log_ber_low = np.log10(lower_point['ber_mean'])
                        log_ber_high = np.log10(upper_point['ber_mean'])
                        log_ber_target = np.log10(target_ber)
                        
                        snr_low = lower_point['snr_db']
                        snr_high = upper_point['snr_db']
                        
                        # Interpolate
                        ratio = (log_ber_target - log_ber_low) / (log_ber_high - log_ber_low)
                        snr_estimate = snr_low + ratio * (snr_high - snr_low)
                        
                        # Check if we can insert here
                        can_insert = True
                        for result in results:
                            if abs(snr_estimate - result['snr_db']) < config['min_snr_gap']:
                                can_insert = False
                                break
                        
                        if can_insert and config['snr_start'] <= snr_estimate <= config['snr_max']:
                            print(f"  Targeting BER {target_ber:.1e} at estimated SNR {snr_estimate:.3f} dB")
                            test_snr_point(snr_estimate)
                            added_targeted_point = True
                            break  # Only add one targeted point per iteration
            
            # Phase 2b: If no targeted points added, do gap-based refinement
            if not added_targeted_point:
                # Find the largest gap in log(BER) space
                max_gap = 0
                insert_idx = -1
                best_mid_snr = None
                
                for i in range(len(results) - 1):
                    ber1 = results[i]['ber_mean']
                    ber2 = results[i+1]['ber_mean']
                    
                    # Only consider gaps where both BERs are in our target range
                    if ber1 <= config['ber_high'] and ber1 > 0:  # Skip if BER1 is 0 or too high
                        # Calculate log gap, handling zero BER cases properly
                        if ber2 == 0:
                            # If second point is 0, calculate gap from ber1 to our target threshold
                            log_gap = abs(np.log10(ber1) - np.log10(config['ber_low']))
                        elif ber2 >= config['ber_low']:
                            # Both BERs are in valid range and non-zero
                            log_gap = abs(np.log10(ber1) - np.log10(ber2))
                        else:
                            # ber2 is below our target threshold, skip this gap
                            continue
                        
                        # Issue 6: Check if we can actually insert a point here
                        snr1 = results[i]['snr_db']
                        snr2 = results[i+1]['snr_db']
                        snr_gap = snr2 - snr1
                        mid_snr = (snr1 + snr2) / 2
                        
                        # Check if insertion point is valid (not too close to existing points)
                        can_insert = True
                        for result in results:
                            if abs(mid_snr - result['snr_db']) < config['min_snr_gap']:
                                can_insert = False
                                break
                        
                        if log_gap > max_gap and snr_gap > 2 * config['min_snr_gap'] and can_insert:
                            max_gap = log_gap
                            insert_idx = i
                            best_mid_snr = mid_snr
                            # print(f"  Found BER gap: {ber1:.2e} to {ber2:.2e} (log gap: {log_gap:.2f}, SNR gap: {snr_gap:.3f} dB)")
                
                if max_gap < config['min_ber_gap']:
                    print(f"Stopping refinement: Maximum BER gap {max_gap:.2f} < {config['min_ber_gap']}")
                    break
                
                if insert_idx == -1 or best_mid_snr is None:
                    print("No valid gaps found for refinement (SNR constraints prevent insertion)")
                    break
                
                # Add the point
                ber1 = results[insert_idx]['ber_mean']
                ber2 = results[insert_idx+1]['ber_mean']
                print(f"Adding gap refinement point at {best_mid_snr:.3f} dB between BER {ber1:.2e} and {ber2:.2e} (log gap: {max_gap:.2f})")
                test_snr_point(best_mid_snr)
    
    print(f"\nCompleted binary search sweep with {len(results)} data points")
    print(f"Performance cliff characterized between {upper_boundary:.3f} dB and {lower_boundary:.3f} dB")
    
    # Save results
    log_data = {
        "timestamp": timestamp,
        "config": "binary_search",
        "pam_level": pam_level,
        "rs_code": [n, k] if not raw_mode else None,
        "raw_mode": raw_mode,
        "results": results,
        "metadata": {
            "description": config['description'],
            "data_size": config['data_size'],
            "total_iterations": config['iterations'],
            "binary_search_parameters": {
                "snr_start": config['snr_start'],
                "snr_max": config['snr_max'],
                "ber_high": config['ber_high'],
                "ber_low": config['ber_low'],
                "min_snr_gap": config['min_snr_gap'],
                "min_ber_gap": config['min_ber_gap'],
                "cliff_boundaries": {
                    "upper": upper_boundary,
                    "lower": lower_boundary,
                    "width": cliff_width
                }
            }
        }
    }
    
    os.makedirs("./logs", exist_ok=True)
    with open(log_filename, 'w') as f:
        json.dump(log_data, f, indent=4)
    print(f"Results saved to {log_filename}")
    
    return results

def run_snr_sweep(config_name="high_snr"):
    """Run complete SNR sweep based on configuration"""
    
    if config_name not in CONFIGS:
        print(f"Unknown configuration: {config_name}")
        print(f"Available configurations: {list(CONFIGS.keys())}")
        return
    
    # Clean directories first
    clean_directories()
    
    config = CONFIGS[config_name]
    print(f"Running {config['description']}")
    
    # Create timestamp for this run
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # Determine which sweep method to use based on continuous mode
    continuous_mode = config.get('continuous_mode', {})
    use_linear_sweep = continuous_mode.get('enabled', False)
    
    if use_linear_sweep:
        print("Using linear SNR sweep for continuous mode")
        sweep_function = run_linear_snr_sweep
    else:
        print("Using binary search SNR sweep")
        sweep_function = run_binary_search_sweep
    
    # Run tests for each PAM/RS combination
    for pam_level in config['pam_levels']:
        if config.get('raw_mode', False):
            # Raw transmission mode (no RS)
            sweep_function(None, None, pam_level, config, timestamp)
        else:
            # RS-coded transmission
            for n, k in config['rs_codes']:
                sweep_function(n, k, pam_level, config, timestamp)
    
    print("SNR sweep completed!")
    print("Use 'python parse.py' to generate plots from the results.")

def list_configurations():
    """List available test configurations"""
    print("Available test configurations:")
    print()
    for name, config in CONFIGS.items():
        print(f"{name}:")
        print(f"  Description: {config['description']}")
        
        # Check if this is a continuous mode configuration
        continuous_mode = config.get('continuous_mode', {})
        if continuous_mode.get('enabled', False):
            print(f"  SNR range: {config['snr_start']}-{config['snr_max']} dB (linear sweep, step: {config.get('snr_step', 'N/A')} dB)")
        else:
            print(f"  SNR range: {config['snr_start']}-{config['snr_max']} dB (binary search)")
            print(f"  BER range: {config['ber_low']:.1e} to {config['ber_high']:.1e}")
            print(f"  Points: {config['min_points']}-{config['max_points']}")
        
        print(f"  Iterations: {config['iterations']}")
        print(f"  Data size: {config['data_size']}")
        print(f"  PAM levels: {config['pam_levels']}")
        print(f"  RS codes: {config['rs_codes']}")
        raw_mode = config.get('raw_mode', False)
        print(f"  Mode: {'Raw transmission' if raw_mode else 'Reed-Solomon coded'}")
        
        # Display continuous mode configuration
        if continuous_mode.get('enabled', False):
            print(f"  Continuous mode: Enabled")
            print(f"    Max bit errors: {continuous_mode.get('max_bit_errors', 10)}")
            print(f"    Max data symbols: {continuous_mode.get('max_data_symbols', 1000000)}")
            print(f"    Chunk size: {continuous_mode.get('chunk_size', 1000)}")
        else:
            print(f"  Continuous mode: Disabled")
        print()

if __name__ == "__main__":
    if len(sys.argv) > 1:
        if sys.argv[1] == "list":
            list_configurations()
        else:
            config_name = sys.argv[1]
            run_snr_sweep(config_name)
    else:
        print("Usage: python tester.py [config_name]")
        print("       python tester.py list")
        print()
        list_configurations()