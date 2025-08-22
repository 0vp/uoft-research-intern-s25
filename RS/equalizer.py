import numpy as np
import scipy as sp

from slicer import Slicer
from pam import PAM

# mu
# 0.0000001 (low 69 and 102)
# 0.000000001 (low 544)

class LMS:
    def __init__(self, mu=0.0000000005, symbol_seperation=48, ffe=None, dfe=None, pam=None):
        self.mu = mu  # step size / learning rate
        self.symbol_separation = symbol_seperation
        self.ffe = ffe
        self.dfe = dfe

        # Use existing PAM instance or create new one as fallback
        self.pam = pam if pam is not None else PAM(n=4, symbol_separation=symbol_seperation)
    
    def equalize(self, data, reference=None, update_rate=1):
        # get tap weights & stats
        if not self.ffe or not self.dfe:
            return data  # Return data unchanged if equalizers not available
            
        ffe_tw = np.array(self.ffe.tap_weights)
        ffe_n_pre_taps = self.ffe.n_pre_taps
        ffe_n_post_taps = self.ffe.n_post_taps
        ffe_n_taps = ffe_n_pre_taps + ffe_n_post_taps + 1

        dfe_tw = np.array(self.dfe.tap_weights[1:]) # skip the main cursor tap
        dfe_n_taps = len(dfe_tw)                    # no cursor

        print("FFE Tap Weights B4:", ffe_tw)
        print("DFE Tap Weights B4:", dfe_tw)

        # lms on weights
        """
        Start at offset: Skip the beginning where we don't have enough data
        End at len(data) - ffe_n_pre_taps: Stop before we run out of future samples for FFE pre-taps

        recall: h = [pre-cursor1, pre-cursor2, ..., cursor, post-cursor1, post-cursor2, ...]

        Data: [x, x, x, x, x, DATA, DATA, DATA, x, x, x]
                ↑           ↑                    ↑
            offset      valid range         end boundary
            (skip these)  (process these)    (skip these)
        """
        N = len(data)
        e = np.zeros(N)     # error array
        ffe_o = np.zeros(N) # ffe equalizer output
        dfe_o = np.zeros(N) # dfe equalizer output
        s = np.zeros(N)     # symbol decisions

        offset = max(ffe_n_post_taps, dfe_n_taps)  # offset for the main cursor tap
        for i in range(offset, N - ffe_n_pre_taps):
            # [::-1] reverse as we want the taps to be in the order of [pre-cursor1, pre-cursor2, ..., cursor, post-cursor1, post-cursor2, ...]
            ffe_i = np.array(data[i - ffe_n_post_taps:i + ffe_n_pre_taps + 1][::-1])  # FFE input slice
            dfe_i = np.array(s[i - dfe_n_taps:i][::-1])                               # DFE input slice / past decisions
            dfe_i = np.array([self.pam.get_level(int(symbol)) for symbol in dfe_i]) # map dfe_i to PAM symbols

            # ffe & dfe equalization
            ffe_o[i] = np.dot(ffe_i, ffe_tw)
            dfe_o[i] = ffe_o[i] - np.dot(dfe_i, dfe_tw)

            # reference decision
            s[i] = self.pam.demodulate([dfe_o[i]])[0]  # hard decision using PAM class
            ref = reference[i] if reference is not None else self.pam.get_level(int(s[i]))  # use reference (training) - else use past decisions.

            # error calculation
            e[i] = dfe_o[i] - ref
            # print(f"e[{i}]: {e[i]} = dfe_o[{i}]: {dfe_o[i]} - ref: {ref} || ffe_o[{i}]: {ffe_o[i]}, ffe_i: {ffe_i}, dfe_i: {dfe_i}")

            # update the weights
            ffe_tw -= self.mu * e[i] * ffe_i
            dfe_tw += self.mu * e[i] * dfe_i

            # print(f"mu: {self.mu}, e[{i}]: {e[i]}, ffe_i: {ffe_i}, dfe_i: {dfe_i}")

        print("FFE Tap Weights Aft:", ffe_tw)
        print("DFE Tap Weights Aft:", dfe_tw)

        self.ffe.tap_weights = ffe_tw.tolist()
        self.dfe.tap_weights = [1] + dfe_tw.tolist()  # keep the main cursor tap as 1

class FFE:
    def __init__(self, tap_weights=None, n_pre_taps=0, n_post_taps=1):
        self.tap_weights = np.array(tap_weights) if tap_weights is not None else np.zeros(n_pre_taps + n_post_taps + 1)
        self.tap_weights[n_pre_taps] = 1  # set the main cursor tap to 1
        self.n_pre_taps = n_pre_taps
        self.n_post_taps = n_post_taps

    def equalize(self, data):
        """Richard's FFE_BR implementation"""
        return sp.signal.fftconvolve(data, self.tap_weights, mode="same")
    
    def zero_forcing(self, channel_coefficients, n_pre_cursors, target=None):
        """
        channel_coefficients: the channel coefficients [h_(-1), h_0, h_1, ...] where h_0 is the cursor.
        n_pre_cursors: number of pre-cursors
        target: what you want the 'shape' after equalization to look like. (shape: (n_taps, 1))
        """
        channel_coefficients = np.array(channel_coefficients)
        n_taps = len(channel_coefficients)
        n_post_cursors = n_taps - n_pre_cursors - 1

        # create the (HᴴH)⁻¹Hᴴ matrix
        H = np.zeros((n_taps, n_taps))

        # built the H matrix
        for tap_i in range(n_taps):
            channel_coef = channel_coefficients[tap_i]  # current coeff
            diagonal_offset = n_pre_cursors - tap_i     # offset from the main tap (cursor)
            
            # fill the diagonal
            for i in range(n_taps):
                j = i + diagonal_offset
                if 0 <= j < n_taps:
                    H[i, j] += channel_coef

        if target == None:
            # do zero-forcing
            c = np.zeros((n_taps, 1))
            c[n_pre_cursors] = 1
        else:
            c = target
        
        # we want to solve H * x = c, so we directly solve
        x = np.linalg.solve(H, c)

        # normalize the taps (main cursor should be 1)
        x /= x[n_pre_cursors]
        x = x.flatten().tolist()

        print("FFE Tap Weights:", x)
        self.tap_weights = x

class DFE:
    def __init__(self, symbol_seperation=48, tap_weights=None, n_taps=2, pam=None):

        self.tap_weights = tap_weights if tap_weights is not None else [1.] + [0.] * (n_taps - 1) # [cursor, post-cursor1, post-cursor2, ...]
        self.symbol_separation = symbol_seperation
        self.prev_symbols = [0] * (len(self.tap_weights) - 1)  #sStore previous decisions

        # Use existing PAM instance or create new one as fallback
        self.pam = pam if pam is not None else PAM(n=4, symbol_separation=symbol_seperation)
    
    def equalize(self, data):
        decisions = []
        for symbol in data:
            # apply cursor tap (main tap)
            equalized_signal = symbol * self.tap_weights[0]
            
            # subtract ISI from previous symbols using post-cursor taps, but the symbol should be in 4-pam so we use the pam class
            for i, prev_symbol in enumerate(self.prev_symbols):
                equalized_signal -= self.tap_weights[i + 1] * self.pam.get_level(prev_symbol)
            
            # hard decision using PAM class
            symbol_out = self.pam.demodulate([equalized_signal])[0]
            decisions.append(symbol_out)
            
            # update previous symbols buffer
            self.prev_symbols = [symbol_out] + self.prev_symbols[:-1]
        
        return decisions