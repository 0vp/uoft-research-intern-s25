
import json
import matplotlib.pyplot as plt
import numpy as np
import os

from matplotlib.ticker import FormatStrFormatter

def load_results(json_path, key):
    with open(json_path, 'r') as f:
        data = json.load(f)
    snrs = []
    cers = []
    for entry in data:
        results = entry.get('results', {})
        snr = results.get('SNR')
        cer = results.get(key)
        if snr is not None and cer is not None and cer != '':
            # Remove ' dB' and convert to float
            snrs.append(float(snr.replace(' dB','')))
            cers.append(float(cer))
    return np.array(snrs), np.array(cers)

def main():
    # Add more datasets here as needed
    datasets = [
        # Baseline/Full protection
        {
            'json': 'full_sova_simulations.json',
            'label': 'Full protection mode (AWGN)',
            'color': '#1f77b4',
            'linestyle': '-',
            'marker': 's',
            'key': 'BER (Post-FEC)',
        },
        
        # 1D RS codes - Green family
        {
            'json': 'full_1d_simulations.json',
            'label': '1D RS(200, 168)',
            'color': '#2ca02c',
            'linestyle': '-',
            'marker': 'o',
            'key': 'BER (Post-FEC)',
        },
        {
            'json': 'full_1d_15_11.json',
            'label': '1D RS(15, 11)',
            'color': '#98df8a',
            'linestyle': '-',
            'marker': 'D',
            'key': 'BER (Post-FEC)',
        },
        
        # 2D RS(15,11) - Purple family with MAX_ITERATIONS variation
        {
            'json': 'full_2d_15_11.json',
            'label': '2D RS(15, 11) MAX_ITERATIONS=8',
            'color': '#7f00ff',
            'linestyle': '-',
            'marker': '^',
            'key': 'BER (Post-FEC)',
        },
        {
            'json': 'full_2d_15_11_m2.json',
            'label': '2D RS(15, 11) MAX_ITERATIONS=2',
            'color': '#b88eee',
            'linestyle': '--',
            'marker': 'v',
            'key': 'BER (Post-FEC)',
        },
        {
            'json': 'full_2d_15_11_m1.json',
            'label': '2D RS(15, 11) MAX_ITERATIONS=1',
            'color': '#dcc9ff',
            'linestyle': ':',
            'marker': '<',
            'key': 'BER (Post-FEC)',
        },
        
        # 2D RS(31,27) - Orange/Red family with CI comparison
        {
            'json': 'full_2d_31_27_ci_bypass.json',
            'label': '2D RS(31, 27) CI Bypass',
            'color': '#ff7f0e',
            'linestyle': '--',
            'marker': 'x',
            'key': 'BER (Post-FEC)',
        },

        # for pre and post CI (M=8, W=1, D=192, P=3)
        {
            'json': 'full_2d_31_27_ci_en.json',
            'label': '2D RS(31, 27) CI Enabled (M=8, W=1, D=192, P=3)',
            'color': '#d62728',
            'linestyle': '-',
            'marker': '*',
            'key': 'BER (Post-FEC)',
        },
        {
            'json': 'full_2d_31_27_ci_bypass.json',
            'label': '2D RS(31, 27) CI Bypass (M=8, W=1, D=192, P=3)',
            'color': '#ff7f0e',
            'linestyle': '--',
            'marker': 'P',
            'key': 'BER (Pre-FEC)',
        },
    ]
    plt.figure(figsize=(12,5))

    for ds in datasets:
        json_path = os.path.join(os.path.dirname(__file__), ds['json'])
        key = ds['key']
        snrs, cers = load_results(json_path, key)
        plt.plot(snrs, cers, label=ds['label'], color=ds['color'], linestyle=ds['linestyle'], marker=ds['marker'], markersize=7, markeredgecolor='black', markerfacecolor='black')

    # 1e-9 target line
    plt.axhline(1e-9, color='red', linestyle='--', linewidth=3, label='1e-9 target')
    # Software simulation limit (example at 1e-6)
    plt.axhline(3.14e-6, color='gray', linestyle='--', linewidth=2, label='Software simulation limit')

    plt.yscale('log')
    plt.xlabel('SNR [dB]', fontsize=16)
    plt.ylabel('Bit Error Rate (Post-FEC)', fontsize=16)
    plt.xticks(fontsize=12)
    plt.yticks(fontsize=12)
    plt.xlim(5, 16)
    plt.ylim(1e-9, 1e0)
    # Only major grid lines, no minor log lines
    plt.grid(True, which='major', axis='y', linestyle='--', alpha=0.5)
    # Add vertical lines for each 0.1 SNR step
    for x in np.arange(0, 17.6, 0.1):
        plt.axvline(x, color='gray', linestyle=':', linewidth=0.8, alpha=0.5, zorder=0)
    plt.legend(fontsize=12, loc='best', frameon=True, fancybox=True, edgecolor='black')
    plt.tight_layout()

    # Format y-axis in scientific E notation
    plt.gca().yaxis.set_major_formatter(FormatStrFormatter('%.0E'))

    # plt.show()
    output_path = os.path.join(os.path.dirname(__file__), 'ber_plot.png')
    plt.savefig(output_path, bbox_inches='tight')
    print(f"Plot saved to {output_path}")

if __name__ == '__main__':
    main()
