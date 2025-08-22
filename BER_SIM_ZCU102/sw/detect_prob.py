import numpy as np
import math

hex_values = [
    0x988d2338944b280,0x1c853c939a371000,0x2f42863b0e417200,0x41986a710820a000,0x5361491abc6a5800,0x647b0ca32abbac00,0x74c7ea12e16db800,0x842ef478d2fc8000,0x929c7f4dc6ce9000,0xa0024e2a82cef000,0xac5792cd7da09800,0xb798bcdaf38cd000,0xc1c720d3909b7000,0xcae87d55f8008800,0xd30666ccde6bf000,0xda2da228842c9000,0xe06d77349ad39800,0xe5d702922ea84000,0xea7c8e6e9d987800,0xee70f7d85bf51000,0xf1c7252da78af000,0xf49190ad1e8f5800,0xf6e1e8c671b17000,0xf8c8c67f91268000,0xfa557928b4c50000,0xfb95e5b979516000,0xfc96778f416b7000,0xfd621fe03abd4000,0xfe026109d7c2f800,0xfe7f62e53dcf5800,0xfee00d764ad38000,0xff2a278ff34a2800,0xff627760943bf000,0xff8ce33930ff5800,0xffac9143aa1ab800,0xffc40537bf1ae800,0xffd53b70dd7f0800,0xffe1c10cc5f1d000,0xffeac8f3cfa51000,0xfff13dd715a9f000,0xfff5d1500fdb6800,0xfff908617ecf8000,0xfffb45a4f519b000,0xfffcd1748bae3000,0xfffde05f443d4000,0xfffe9831e4790000,0xffff13d7127ff800,0xffff664949448800,0xffff9cc8b3283000,0xffffc07eb1e1c800,0xffffd7b1386e2800,0xffffe6a1565f9000,0xfffff02a82b3d000,0xfffff633575bd000,0xfffff9fc765f7000,0xfffffc5725a51000,0xfffffdcab2675000,0xfffffeadc4355000,0xffffff375577d000,0xffffff89f448d000,0xffffffbb24d4d800,0xffffffd82cfd2800,0xffffffe92967b000,0xffffffffffffffff
]

BLOCK_SIZE = 64
amps       = np.arange(BLOCK_SIZE, dtype=np.float64)
var_s      = ((2**7 - 1)**2) / 3            # signal variance for ±127 NRZ

thr = np.array(hex_values, dtype=np.uint64)
n_blocks = len(thr) // BLOCK_SIZE
snr_list = []

for b in range(n_blocks):
    start = b * BLOCK_SIZE
    stop  = start + BLOCK_SIZE
    thr_block = thr[start:stop]

    # PDF of |n|  (length 64)
    p = np.diff(np.hstack(([0], thr_block))) / 2.0**64

    var_n = 2 * np.sum(p * amps**2)        # factor 2 → add sign symmetry
    snr_db = 10 * math.log10(var_s / var_n)
    snr_list.append(snr_db)

    print(f"Block {b:2d}:  SNR ≈ {snr_db:6.2f} dB")
