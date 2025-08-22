import random
import numpy as np
import scipy as sp
import sys
import argparse

from reedsolomon import ReedSolomon1D, ReedSolomon2D
from encode import Binary, GrayCode
from slicer import Slicer
from equalizer import FFE, DFE, LMS
from pam import PAM

"""
Enhanced PAM/Reed-Solomon Communication System

USAGE: python model.py [OPTIONS]

Use --help to see all available options and defaults.

Examples:
# Basic 4-PAM test with defaults
python model.py --pam_levels 4 --snr_db 20.0

# 6-PAM with RS(69,65) and custom data size
python model.py --n 69 --k 65 --pam_levels 6 --snr_db 25.0 --data_size 512

# 8-PAM with direct sigma input (bypasses SNR calculation)
python model.py --n 102 --k 96 --pam_levels 8 --sigma 0.1 --training_size 200

# High precision LMS with custom parameters
python model.py --mu 0.0000001 --max_iterations 500 --pam_levels 6

# Quick test with minimal data
python model.py --data_size 32 --training_size 50
"""

DEBUG = True

def debug_print(*args, **kwargs):
    if DEBUG:
        print(*args, **kwargs)

def calculate_sigma_from_snr(snr_db, pam_level, symbol_separation=48):
    """Calculate noise sigma for given SNR using peak power normalization"""
    
    # Peak power normalization: V_pk^2 / sigma_noise^2
    # Peak voltage is symbol_separation (since normalized levels have peak = ±1)
    peak_power = symbol_separation**2
    
    snr_linear = 10 ** (snr_db / 10)
    noise_power = peak_power / snr_linear
    return np.sqrt(noise_power)

class Transmitter:
    def __init__(self, channel=None, config=None, pam=None, raw=True):
        """
        raw: if True, we add equalizers and RS, otherwise we just send the data raw.
        """
        self.channel = channel
        self.config = config or {}
        self.pam = pam

        self.N = self.config.get("N") or 16
        self.K = self.config.get("K") or 8
        self.N_ERR = self.config.get("N_ERR") or 3
        self.MODE = self.config.get("MODE", "1D")
        self.METHOD = self.config.get("METHOD", "random")
        self.SEED = self.config.get("SEED", 0)

        self.raw = raw
        
        # Store original data for error calculation
        self.original_symbols = []

    def transmit(self, data):
        "transmit the data through the channel"
        tx_data = []
        
        # Store original data for error calculation
        self.original_symbols = data.copy()

        if self.MODE == "1D":
            rs = ReedSolomon1D(self.N, self.K)
            size = self.K
        elif self.MODE == "2D":
            rs = ReedSolomon2D(self.N, self.K)
            size = self.K * self.K if not self.raw else self.N * self.N

        # encode each chunk individually (like physical systems)
        for i in range(len(data)):
            # get data of size, and if not enough, fill with zeros
            if i * size >= len(data):
                break

            data_slice = data[i * size:(i + 1) * size]
            if len(data_slice) < size:
                data_slice += [0] * (size - len(data_slice))

            # encode this chunk
            encoded_chunk = self.encode(rs, data_slice)
            tx_data.extend(encoded_chunk)

        # modulate the data
        if self.pam:
            tx_data = self.pam.modulate(tx_data)

        if self.channel:
            self.channel.read(tx_data)

    def encode(self, rs, data):
        "encode (RS + Gray) the data before transmission"
        
        # Get PAM levels - default to 4 if no PAM object or for backwards compatibility
        n_levels = self.pam.n if self.pam else 4
        
        # rs encoding
        if self.raw:
            encoded_data = data
        else:
            encoded_data = rs.encode(data, self.N, self.K)

        # bit encoding
        encoded_bits = Binary.bit_encode(encoded_data)
        
        # gray encoding (each chunk pads itself - like physical systems)
        encoded_data = GrayCode.gray_encode(list(encoded_bits), n_levels)

        return encoded_data



class Channel:
    def __init__(self, h=None, receiver=None, config=None, clean=False, sigma=None):
        self.receiver = receiver
        self.config = config or {}
        self.h = h if h is not None else [1, 0.5]  # default channel response
        self.sigma = sigma if sigma is not None else self.config.get("SIGMA", 5)  # default sigma
        self.clean = clean  # if True, we don't apply ISI or noise

    def get_channel_response(self):
        return self.h

    def convolve(self, data):
        np_data = np.array(data)
        np_h = np.array(self.h)

        # convolve the data with the channel response
        convolved_data = np.convolve(np_data, np_h, mode='same')
        convolved_data = convolved_data.tolist()

        return convolved_data

    def add_noise(self, data, mode="gaussian", range=(-12, 12)):
        "add noise to the data based on the mode"

        if mode == "none":
            return data
        elif mode == "gaussian":
            noise = np.random.normal(0, self.sigma, len(data))
            return [d + n for d, n in zip(data, noise)]
        elif mode == "uniform":
            # add uniform noise
            noise = [random.randint(range[0], range[1]) for _ in data]
            return [d + n for d, n in zip(data, noise)]
        else:
            raise ValueError(f"Unknown noise mode: {mode}")

    def read(self, data):
        "get the data from the transmitter"
        # debug_print(f"Channel received data: {data}")

        # convolve with channel response
        if not self.clean:
            data = self.convolve(data)
        # debug_print(f"Data after convolution: {data}")

        # send to the receiver
        self.write(data)

    def write(self, data):
        "put the data into the receiver"
        if not self.clean:
            data = self.add_noise(data, mode="gaussian")  # or "uniform" with range
        # debug_print(f"Data after noise addition: {data}")

        if self.receiver:
            self.receiver.receive(data)

class Receiver:
    def __init__(self, config=None, ffe=None, dfe=None, lms=None, pam=None, raw=True, adapt_weights=False):
        """
        raw: if True, we add equalizers and RS, otherwise we just send the data raw.
        """
        self.config = config or {}
        self.N = self.config.get("N") or 16
        self.K = self.config.get("K") or 8
        self.MODE = self.config.get("MODE", "1D")

        self.received = []
        self.reference = [] # n-pam symbols received from the channel (for equalizer training)

        self.ffe = ffe
        self.dfe = dfe
        self.lms = lms
        self.pam = pam

        self.raw = raw # if True, no corrections / equalizer
        self.adapt_weights = adapt_weights  # if True, we adapt the weights of the equalizers
        
        # Cumulative error counter attributes for continuous mode
        self.cumulative_bit_errors = 0
        self.cumulative_symbol_errors = 0
        self.cumulative_bits_processed = 0
        self.cumulative_symbols_processed = 0
        
    def train_equalizer(self, channel, eq_mode="zero_forcing"):
        """
        train the equalizer - zero forcing for FFE
        """
        h = channel.get_channel_response()
        
        # count how many pre-cursors we have - this won't always work but we assume this is true for now.
        n_pre_cursors = 0
        for i in range(len(h)):
            if h[i] == 1:
                break
            n_pre_cursors += 1

        if eq_mode == "zero_forcing":
            # zero forcing equalizer
            if self.ffe:
                self.ffe.zero_forcing(h, n_pre_cursors)
                debug_print(f"FFE trained with zero forcing: {self.ffe.tap_weights}")
        elif eq_mode == "lms":
            pass

    def reset_error_counters(self):
        """Initialize error tracking counters for continuous mode"""
        self.cumulative_bit_errors = 0
        self.cumulative_symbol_errors = 0
        self.cumulative_bits_processed = 0
        self.cumulative_symbols_processed = 0

    def update_error_counters(self, original_chunk, received_chunk):
        """Update error counters after each chunk processing using same logic as calculate_ber"""
        min_length = min(len(original_chunk), len(received_chunk))
        if min_length > 0:
            # Symbol errors - same logic as existing SER calculation
            chunk_symbol_errors = sum(1 for a, b in zip(original_chunk[:min_length], received_chunk[:min_length]) if a != b)
            
            # Bit errors - same logic as existing calculate_ber method
            original_bits = Binary.bit_encode(original_chunk[:min_length])
            received_bits = Binary.bit_encode(received_chunk[:min_length])
            min_bit_length = min(len(original_bits), len(received_bits))
            chunk_bit_errors = sum(1 for a, b in zip(original_bits[:min_bit_length], received_bits[:min_bit_length]) if a != b)
            
            # Update cumulative counters
            self.cumulative_symbol_errors += chunk_symbol_errors
            self.cumulative_bit_errors += chunk_bit_errors
            self.cumulative_symbols_processed += min_length
            self.cumulative_bits_processed += min_bit_length

    def get_cumulative_stats(self):
        """Return current cumulative BER/SER statistics"""
        ber = self.cumulative_bit_errors / self.cumulative_bits_processed if self.cumulative_bits_processed > 0 else 1.0
        ser = self.cumulative_symbol_errors / self.cumulative_symbols_processed if self.cumulative_symbols_processed > 0 else 1.0
        
        return {
            'ber': ber,
            'ser': ser,
            'bit_errors': self.cumulative_bit_errors,
            'symbol_errors': self.cumulative_symbol_errors,
            'total_bits': self.cumulative_bits_processed,
            'total_symbols': self.cumulative_symbols_processed
        }

    def calculate_ber(self, transmitter):
        """Calculate BER by comparing original symbols vs final received symbols"""
        min_length = min(len(transmitter.original_symbols), len(self.received))
        if min_length > 0:
            # Convert original symbols to bits
            original_symbol_bits = Binary.bit_encode(transmitter.original_symbols[:min_length])
            # Convert received symbols to bits  
            received_symbol_bits = Binary.bit_encode(self.received[:min_length])
            
            # Compare bits
            min_bit_length = min(len(original_symbol_bits), len(received_symbol_bits))
            bit_errors = sum(1 for a, b in zip(original_symbol_bits[:min_bit_length], received_symbol_bits[:min_bit_length]) if a != b)
            total_bits = min_bit_length
            ber = bit_errors / total_bits if total_bits > 0 else 1.0
        else:
            bit_errors = 0
            total_bits = 0
            ber = 1.0
        
        return {
            'ber': ber,
            'bit_errors': bit_errors,
            'total_bits': total_bits
        }

    def decode(self, data):
        "decode the received data"
        
        # Get PAM levels - default to 4 if no PAM object or for backwards compatibility
        n_levels = self.pam.n if self.pam else 4
        
        if self.MODE == "1D":
            rs = ReedSolomon1D(self.N, self.K)
            decode_args = (self.N, self.K)
            size = self.N
            # Calculate expected bits per chunk (before RS encoding)
            expected_bits_per_chunk = self.K * 16
        elif self.MODE == "2D":
            rs = ReedSolomon2D(self.N, self.K)
            max_iterations = self.config.get("MAX_ITERATIONS_RS_2D", 250)
            decode_args = (self.N, self.K, max_iterations)
            size = self.N * self.N
            # Calculate expected bits per chunk (before RS encoding)  
            expected_bits_per_chunk = self.K * self.K * 16

        # Calculate how many gray symbols each chunk should produce
        bits_per_symbol = 2 if n_levels == 4 else (5 if n_levels == 6 else 3)
        if n_levels == 6:
            # Special case: 6-PAM uses 5:2 block encoding
            expected_gray_symbols_per_chunk = ((size * 16 + 4) // 5) * 2  # Round up to multiple of 5, then convert
        else:
            expected_gray_symbols_per_chunk = ((size * 16 + bits_per_symbol - 1) // bits_per_symbol)  # Round up

        # Process each chunk individually to strip padding
        all_clean_bits = []
        
        for i in range(0, len(data), expected_gray_symbols_per_chunk):
            # Extract chunk
            chunk_symbols = data[i:i + expected_gray_symbols_per_chunk]
            if len(chunk_symbols) < expected_gray_symbols_per_chunk:
                break  # Skip incomplete chunks
            
            # Gray decode this chunk (includes padding)
            chunk_bits = GrayCode.gray_decode(chunk_symbols, n_levels)
            
            # Remove padding: trim to expected length
            clean_chunk_bits = chunk_bits[:expected_bits_per_chunk + (size - (self.K if self.MODE == "1D" else self.K * self.K)) * 16]
            all_clean_bits.extend(clean_chunk_bits)
        
        # Convert clean bits back to symbols and process normally
        decoded_data = Binary.bit_decode(all_clean_bits)

        # rs decode - decode each 'size' symbols
        symbols = []
        if self.raw:
            symbols = decoded_data
        else:
            for i in range(0, len(decoded_data), size):
                data_slice = decoded_data[i:i + size]
                if len(data_slice) < size:
                    data_slice += [0] * (size - len(data_slice))

                decoded_slice = rs.decode(data_slice, *decode_args)
                if decoded_slice is None:
                    symbols.extend(data_slice[:self.K if self.MODE == "1D" else self.K * self.K])
                else:
                    symbols.extend(decoded_slice if self.MODE == "1D" else decoded_slice)

        return symbols

    def receive(self, data):
        "receive the data from the channel"
        # debug_print(f"Receiver received data: {data}")

        # print(f"1. eceived data ({len(data)}): {data[:16]}")
        self.reference = data[:]

        if not self.raw:
            # if we are fixing, we need to equalize the data first
            p = 16
            # if we are using LMS, we need to adapt the weights
            if self.adapt_weights and self.lms is not None:
                self.lms.mu = self.lms.mu * 0.1  # reduce the learning rate for adaptation - hardcoded for now
                self.lms.equalize(data)
                
            # equalize the data
            # print("data before equalization:", data[:p])
            if self.ffe:
                data = self.ffe.equalize(data)
            # print("data after FFE:", data[:p])
            if self.dfe:
                data = self.dfe.equalize(data)
            # print("data after equalization:", data[:p])
        else:
            # hard slice the data using PAM
            if self.pam:
                data = self.pam.demodulate(data)
            else:
                # Fallback: use hard slicer with default parameters (4-PAM)
                data = Slicer.hard_slicer(data, symbol_separation=48, n_levels=4)

        # decode
        decoded_data = self.decode(data)
        # debug_print(f"Decoded data: {decoded_data}")

        # store the received data
        self.received = decoded_data[:]

def run_single_mode(args):
    """Run single-shot mode (existing behavior)"""
    # Use parsed arguments
    N = args.n
    K = args.k
    MAX_ITERATIONS_RS_2D = args.max_iterations
    mu = args.mu
    pam_levels = args.pam_levels
    data_size = args.data_size
    training_size = args.training_size
    raw_mode = args.raw
    clean_mode = args.clean
    
    # Use consistent symbol separation for peak power normalization
    symbol_separation = 48.0
    
    # Determine sigma: use provided sigma or calculate from SNR
    if args.sigma is not None:
        sigma = args.sigma
        mode_str = "RAW" if raw_mode else f"RS({N},{K})"
        print(f"Testing {mode_str} with {pam_levels}-PAM using sigma={sigma}")
    else:
        snr_db = args.snr_db
        sigma = calculate_sigma_from_snr(snr_db, pam_levels, symbol_separation)
        mode_str = "RAW" if raw_mode else f"RS({N},{K})"
        print(f"Testing {mode_str} with {pam_levels}-PAM at {snr_db} dB SNR (peak power normalized)")
        print(f"Calculated sigma: {sigma:.6f}")
    
    print(f"Symbol separation: {symbol_separation} (peak power normalization)")
    
    mode_flags = []
    if raw_mode: mode_flags.append("RAW (no Reed-Solomon)")
    if clean_mode: mode_flags.append("CLEAN (no channel effects)")
    if mode_flags:
        print(f"Mode: {', '.join(mode_flags)}")
    
    print(f"Data size: {data_size}, Training size: {training_size}")
    print()
    
    # Example usage
    h = [0.2, 1.0, 0.4]  # [pre, ..., cursor, post, ...] - channel response

    # Create PAM instance with consistent symbol separation for peak power normalization
    pam = PAM(n=pam_levels, symbol_separation=symbol_separation)

    ffe = FFE(tap_weights=None, n_pre_taps=1, n_post_taps=1)
    dfe = DFE(symbol_seperation=symbol_separation, tap_weights=None, n_taps=2, pam=pam)

    lms = LMS(mu=mu, ffe=ffe, dfe=dfe, pam=pam)

    config = {
        "N": N,
        "K": K,
        "MAX_ITERATIONS_RS_2D": MAX_ITERATIONS_RS_2D,
        "N_ERR": 3,
        "MODE": args.mode,
        "SEED": 0,
        "EQ_MODE": "lms", # "zero_forcing" or "lms" 
    }
    receiver = Receiver(
        config=config,
        ffe=ffe,
        dfe=dfe,
        lms=lms,
        pam=pam,
        raw=raw_mode
    )
    channel = Channel(
        config=config,
        receiver=receiver,
        h=h,
        sigma=sigma,
        clean=clean_mode
    )
    transmitter = Transmitter(
        config=config,
        channel=channel,
        pam=pam,
        raw=raw_mode
    )

    # Skip training and equalization if clean mode is enabled
    if not clean_mode and config['EQ_MODE'] == "lms":
        # Training phase - use random data for better constellation coverage
        training_data = [random.randint(0, 225) for _ in range(training_size)]

        # Clean training (no noise)
        transmitter.raw = True
        receiver.raw = True
        channel.clean = True
        transmitter.transmit(training_data)
        clean_response = receiver.reference[:]

        # Noisy training 
        channel.clean = False
        transmitter.transmit(training_data)
        noisy_response = receiver.reference[:]

        # Train LMS equalizer
        lms.equalize(noisy_response, reference=clean_response)

    # Test phase
    transmitter.raw = raw_mode
    receiver.raw = raw_mode
    channel.clean = clean_mode
    receiver.adapt_weights = not clean_mode  # No adaptation needed in clean mode

    # Generate test data of specified size
    test_data = [random.randint(0, 225) for _ in range(data_size)]

    # Transmit and receive
    transmitter.transmit(test_data)

    # Calculate POST-FEC SER (Final decoded symbols vs original)
    received_data = receiver.received
    min_length = min(len(test_data), len(received_data))
    symbol_errors = sum(1 for a, b in zip(test_data[:min_length], received_data[:min_length]) if a != b)
    ser = symbol_errors / min_length if min_length > 0 else 1.0

    # Calculate POST-FEC BER (Final decoded symbols vs original)
    if min_length > 0:
        # Convert original and final received symbols to bits
        original_bits = Binary.bit_encode(test_data[:min_length])
        received_bits = Binary.bit_encode(received_data[:min_length])
        
        # Compare bits
        min_bit_length = min(len(original_bits), len(received_bits))
        bit_errors = sum(1 for a, b in zip(original_bits[:min_bit_length], received_bits[:min_bit_length]) if a != b)
        ber = bit_errors / min_bit_length if min_bit_length > 0 else 1.0
    else:
        ber = 1.0

    # Print results in original format
    total_bit_errors = int(ber * min_bit_length) if min_length > 0 else 0
    total_bits = min_bit_length if min_length > 0 else 0
    
    print(f"BER: {ber:.5f} ({total_bit_errors} errors in {total_bits} bits)")
    print(f"SER: {ser:.5f} ({symbol_errors} errors in {min_length} symbols)")


def check_error_limit_reached(cumulative_bit_errors, max_bit_errors):
    """Check if the bit error limit has been reached"""
    return cumulative_bit_errors >= max_bit_errors

def check_data_limit_reached(cumulative_symbols_processed, max_data_symbols):
    """Check if the maximum data limit has been reached"""
    return cumulative_symbols_processed >= max_data_symbols

def evaluate_stopping_criteria(cumulative_bit_errors, max_bit_errors, cumulative_symbols_processed, max_data_symbols):
    """
    Evaluate stopping criteria after each chunk and return stopping decision
    
    Returns:
        tuple: (should_stop, stop_reason)
        - should_stop: boolean indicating if transmission should stop
        - stop_reason: string indicating which criterion was triggered ('error_limit', 'data_limit', or None)
    """
    if check_error_limit_reached(cumulative_bit_errors, max_bit_errors):
        return True, "error_limit"
    elif check_data_limit_reached(cumulative_symbols_processed, max_data_symbols):
        return True, "data_limit"
    else:
        return False, None

def run_continuous_mode(args):
    """Run continuous mode until stopping criteria met"""
    # Use parsed arguments
    N = args.n
    K = args.k
    MAX_ITERATIONS_RS_2D = args.max_iterations
    mu = args.mu
    pam_levels = args.pam_levels
    chunk_size = args.chunk_size
    max_bit_errors = args.max_bit_errors
    max_data_symbols = args.max_data_symbols
    training_size = args.training_size
    raw_mode = args.raw
    clean_mode = args.clean
    
    # Use consistent symbol separation for peak power normalization
    symbol_separation = 48.0
    
    # Determine sigma: use provided sigma or calculate from SNR
    if args.sigma is not None:
        sigma = args.sigma
        mode_str = "RAW" if raw_mode else f"RS({N},{K})"
        print(f"Testing {mode_str} with {pam_levels}-PAM using sigma={sigma} (Continuous Mode)")
    else:
        snr_db = args.snr_db
        sigma = calculate_sigma_from_snr(snr_db, pam_levels, symbol_separation)
        mode_str = "RAW" if raw_mode else f"RS({N},{K})"
        print(f"Testing {mode_str} with {pam_levels}-PAM at {snr_db} dB SNR (peak power normalized) (Continuous Mode)")
        print(f"Calculated sigma: {sigma:.6f}")
    
    print(f"Symbol separation: {symbol_separation} (peak power normalization)")
    
    mode_flags = []
    if raw_mode: mode_flags.append("RAW (no Reed-Solomon)")
    if clean_mode: mode_flags.append("CLEAN (no channel effects)")
    if mode_flags:
        print(f"Mode: {', '.join(mode_flags)}")
    
    print(f"Chunk size: {chunk_size}, Max bit errors: {max_bit_errors}, Max data symbols: {max_data_symbols}")
    print()
    
    # Example usage
    h = [0.2, 1.0, 0.4]  # [pre, ..., cursor, post, ...] - channel response

    # Create PAM instance with consistent symbol separation for peak power normalization
    pam = PAM(n=pam_levels, symbol_separation=symbol_separation)

    ffe = FFE(tap_weights=None, n_pre_taps=1, n_post_taps=1)
    dfe = DFE(symbol_seperation=symbol_separation, tap_weights=None, n_taps=2, pam=pam)

    lms = LMS(mu=mu, ffe=ffe, dfe=dfe, pam=pam)

    config = {
        "N": N,
        "K": K,
        "MAX_ITERATIONS_RS_2D": MAX_ITERATIONS_RS_2D,
        "N_ERR": 3,
        "MODE": args.mode,
        "SEED": 0,
        "EQ_MODE": "lms", # "zero_forcing" or "lms" 
    }
    receiver = Receiver(
        config=config,
        ffe=ffe,
        dfe=dfe,
        lms=lms,
        pam=pam,
        raw=raw_mode
    )
    channel = Channel(
        config=config,
        receiver=receiver,
        h=h,
        sigma=sigma,
        clean=clean_mode
    )
    transmitter = Transmitter(
        config=config,
        channel=channel,
        pam=pam,
        raw=raw_mode
    )

    # Skip training and equalization if clean mode is enabled
    if not clean_mode and config['EQ_MODE'] == "lms":
        # Training phase - use random data for better constellation coverage
        training_data = [random.randint(0, 225) for _ in range(training_size)]

        # Clean training (no noise)
        transmitter.raw = True
        receiver.raw = True
        channel.clean = True
        transmitter.transmit(training_data)
        clean_response = receiver.reference[:]

        # Noisy training 
        channel.clean = False
        transmitter.transmit(training_data)
        noisy_response = receiver.reference[:]

        # Train LMS equalizer
        lms.equalize(noisy_response, reference=clean_response)

    # Test phase - set up for continuous mode
    transmitter.raw = raw_mode
    receiver.raw = raw_mode
    channel.clean = clean_mode
    receiver.adapt_weights = not clean_mode  # No adaptation needed in clean mode

    # Initialize cumulative counters for continuous mode
    cumulative_bit_errors = 0
    cumulative_symbol_errors = 0
    cumulative_bits_processed = 0
    cumulative_symbols_processed = 0
    chunks_processed = 0
    stop_reason = ""

    # Continuous transmission loop
    while True:
        # Generate chunk of random data
        chunk_data = [random.randint(0, 225) for _ in range(chunk_size)]
        
        # Transmit and receive chunk
        transmitter.transmit(chunk_data)
        received_chunk = receiver.received
        
        # Calculate errors for this chunk
        min_length = min(len(chunk_data), len(received_chunk))
        if min_length > 0:
            # Symbol errors
            chunk_symbol_errors = sum(1 for a, b in zip(chunk_data[:min_length], received_chunk[:min_length]) if a != b)
            
            # Bit errors
            original_bits = Binary.bit_encode(chunk_data[:min_length])
            received_bits = Binary.bit_encode(received_chunk[:min_length])
            min_bit_length = min(len(original_bits), len(received_bits))
            chunk_bit_errors = sum(1 for a, b in zip(original_bits[:min_bit_length], received_bits[:min_bit_length]) if a != b)
            
            # Update cumulative counters
            cumulative_symbol_errors += chunk_symbol_errors
            cumulative_bit_errors += chunk_bit_errors
            cumulative_symbols_processed += min_length
            cumulative_bits_processed += min_bit_length
        
        chunks_processed += 1
        
        # Evaluate stopping criteria after each chunk
        should_stop, stop_reason = evaluate_stopping_criteria(
            cumulative_bit_errors, max_bit_errors, 
            cumulative_symbols_processed, max_data_symbols
        )
        
        if should_stop:
            break
    
    # Calculate final statistics
    ber = cumulative_bit_errors / cumulative_bits_processed if cumulative_bits_processed > 0 else 1.0
    ser = cumulative_symbol_errors / cumulative_symbols_processed if cumulative_symbols_processed > 0 else 1.0
    
    # Print results in same format as single mode - exact format compatibility
    print(f"BER: {ber:.5f} ({cumulative_bit_errors} errors in {cumulative_bits_processed} bits)")
    print(f"SER: {ser:.5f} ({cumulative_symbol_errors} errors in {cumulative_symbols_processed} symbols)")
    
    # Report which stopping criterion was triggered (for debugging/validation)
    if stop_reason == "error_limit":
        debug_print(f"Stopped due to error limit: {cumulative_bit_errors} >= {max_bit_errors} bit errors")
    elif stop_reason == "data_limit":
        debug_print(f"Stopped due to data limit: {cumulative_symbols_processed} >= {max_data_symbols} symbols processed")
    debug_print(f"Processed {chunks_processed} chunks total")


def validate_continuous_mode_parameters(args):
    """
    Validate continuous mode parameters and raise appropriate errors for invalid configurations
    
    Args:
        args: Parsed command line arguments
        
    Raises:
        ValueError: If continuous mode parameters are invalid
    """
    if not args.continuous_mode:
        return  # No validation needed if continuous mode is disabled
    
    errors = []
    
    # Validate max_bit_errors > 0
    if args.max_bit_errors <= 0:
        errors.append(f"max_bit_errors must be greater than 0, got {args.max_bit_errors}")
    
    # Validate max_data_symbols > chunk_size
    if args.max_data_symbols <= args.chunk_size:
        errors.append(f"max_data_symbols ({args.max_data_symbols}) must be greater than chunk_size ({args.chunk_size})")
    
    # Validate chunk_size > 0
    if args.chunk_size <= 0:
        errors.append(f"chunk_size must be greater than 0, got {args.chunk_size}")
    
    # Validate max_data_symbols > 0
    if args.max_data_symbols <= 0:
        errors.append(f"max_data_symbols must be greater than 0, got {args.max_data_symbols}")
    
    if errors:
        error_message = "Invalid continuous mode configuration:\n" + "\n".join(f"  - {error}" for error in errors)
        raise ValueError(error_message)


def main():
    """Parse arguments and dispatch to appropriate mode"""
    # Parse command line arguments with argparse
    parser = argparse.ArgumentParser(
        description='Enhanced PAM/Reed-Solomon Communication System',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    
    # Reed-Solomon parameters
    parser.add_argument('--n', type=int, default=16, 
                       help='Reed-Solomon N parameter (codeword length)')
    parser.add_argument('--k', type=int, default=8,
                       help='Reed-Solomon K parameter (message length)')
    parser.add_argument('--max_iterations', type=int, default=250,
                       help='Maximum iterations for 2D RS decoding')
    parser.add_argument('--mode', type=str, default='2D', choices=['1D', '2D'],
                       help='Reed-Solomon decoding mode (1D or 2D)')
    
    # System parameters
    parser.add_argument('--mu', type=float, default=0.00001,
                       help='LMS step size/learning rate')
    parser.add_argument('--pam_levels', type=int, default=4, choices=[4, 6, 8],
                       help='PAM constellation size')
    
    # Noise parameters (mutually exclusive)
    noise_group = parser.add_mutually_exclusive_group()
    noise_group.add_argument('--snr_db', type=float, default=20.0,
                           help='Signal-to-noise ratio in dB (calculates sigma)')
    noise_group.add_argument('--sigma', type=float,
                           help='Noise standard deviation (overrides SNR)')
    
    # Test parameters
    parser.add_argument('--data_size', type=int, default=64,
                       help='Number of symbols to test (single shot)')
    parser.add_argument('--training_size', type=int, default=100,
                       help='Number of symbols for LMS training')
    
    # System mode parameters
    parser.add_argument('--raw', action='store_true',
                       help='Disable Reed-Solomon error correction (raw transmission)')
    parser.add_argument('--clean', action='store_true',
                       help='Disable channel effects (no ISI or noise) for testing')
    
    # Continuous mode parameters
    parser.add_argument('--continuous_mode', action='store_true',
                       help='Enable continuous mode operation')
    parser.add_argument('--max_bit_errors', type=int, default=10,
                       help='Maximum bit errors before stopping in continuous mode')
    parser.add_argument('--max_data_symbols', type=int, default=1000000,
                       help='Maximum symbols to process in continuous mode')
    parser.add_argument('--chunk_size', type=int, default=1000,
                       help='Symbols per processing chunk in continuous mode')
    
    args = parser.parse_args()
    
    # Validate continuous mode parameters
    try:
        validate_continuous_mode_parameters(args)
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Dispatch to appropriate mode
    if args.continuous_mode:
        run_continuous_mode(args)
    else:
        run_single_mode(args)


if __name__ == "__main__":
    main()