import numpy as np
## function definitions

def prbs20(seed):
    """Genterates PRBS20 sequence

    Parameters
    ----------
    seed : int
        seed used to generate sequence
        should be greater than 0 and less than 2^20

    Returns
    -------
    array:
        PRBS20 sequence
    """
    if (type(seed)!= int) or (seed>0xfffff) or (seed < 1):
        print("seed must be positive int less than 2^20")
        return False
    
    code = seed
    seq = np.zeros(2**20-1, dtype=np.uint8)
    i = 0
    sequence_complete = False
    
    while(i<2**20):
        next_bit = ((code>>19) ^ (code>>2)) & 0x00001
        code = ((code<<1) | next_bit) & 0xfffff
        seq[i] = next_bit
        i = i+1
        if (code==seed):
            sequence_complete = True
            break
        
    if sequence_complete:
        return seq
    else:
        print ("error, PRBS sequence did not complete")
        return False

def gray_encode(x):
    """does grey encoding on a sequnce of bits

    Parameters
    ----------
    x : array
        contains the input binary data in a numpy arrau
    
    Returns
    -------
    int
        array of half the length of x contianing grey coded PAM-4 symbols

    """
    if (x.size%2):
        print ("input must be even number of bits")
        return False

    n_bits = x.size
    n_symbols = int(n_bits/2)
    x = x.reshape([n_symbols,2])
    out = np.zeros(n_symbols, dtype=np.uint8)

    #print(x)
    #print(x[0,0])
    for i in range (n_symbols):
        if (x[i,0] == 0):
            if (x[i,1] == 0):
                out[i]=0
            else:
                out[i]=1
        else:
            if (x[i,1] == 0):
                out[i]=3
            else:
                out[i]=2

    return out
        
def gray_decode(symbols):

    n_symbols = symbols.size

    n_bits = int(n_symbols*2)

    out = np.zeros(n_bits, dtype=np.uint8)

    for i in range(n_symbols):
        if symbols[i] == 0:
            out[2*i] = 0
            out[2*i+1] = 0
        elif symbols[i] == 1 :
            out[2*i] = 0
            out[2*i+1] = 1
        elif symbols[i] == 2 :
            out[2*i] = 1
            out[2*i+1] = 1
        elif symbols[i] == 3 :
            out[2*i] = 1
            out[2*i+1] = 0
        else:
            print(i)
            print('unexpected symbol in data_in')
            return False 
    return out

#script begins

#run simulation on 1M bits
n_bits = 1000000

#Generate input data
input_bits = prbs20(1)[:n_bits]

#Gray encode to PAM-4 symbols
input_symbols = gray_encode(input_bits)

n_symbols = input_symbols.size

#standard PAM4 levels
levels = np.array([-3,-1,1,3])

#calculate SNR for noise var of 0.1 AWGN channel
avg_signal_power = np.sum(levels**2)/levels.size
noise_variance = 0.1
noise_standard_deviation = np.sqrt(noise_variance)
SNR_dB = 10*np.log10(avg_signal_power/noise_variance)

print(noise_variance, noise_standard_deviation)
print("SNR of AWGN channel is %.20f dB"%SNR_dB)

signal = np.zeros(n_symbols)

#map symbols to PAM-4 levels
for i in range(n_symbols):
    signal[i] = levels[input_symbols[i]]

#add noise
print(f"signal: {signal}    noise: {np.random.normal(size=n_symbols,scale=noise_standard_deviation)}")
signal_noise = signal + np.random.normal(size=n_symbols,scale=noise_standard_deviation)

#slice
thresholds = np.array([-2,0,2])
output_symbols = np.zeros(n_symbols)
for i in range(n_symbols):
    if signal_noise[i]<thresholds[1]:
        if signal_noise[i]<thresholds[0]:
            output_symbols[i]=0
        else:
            output_symbols[i]=1
    else:
        if signal_noise[i]<thresholds[2]:
            output_symbols[i]=2
        else:
            output_symbols[i]=3

#check SER
n_symbol_errors = np.sum(input_symbols!=output_symbols)
SER = n_symbol_errors/n_symbols
from decimal import Decimal
print("SER is %.2E"%SER)

#check BER
output_bits = gray_decode(output_symbols)
n_bit_errors = np.sum(input_bits!=output_bits)
BER = n_bit_errors/n_bits
print("BER is %.2E"%BER)


