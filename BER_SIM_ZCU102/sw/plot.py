
import json
import matplotlib.pyplot as plt
import numpy as np
import os

from matplotlib.ticker import FormatStrFormatter

def load_results(json_path):
    with open(json_path, 'r') as f:
        data = json.load(f)
    snrs = []
    cers = []
    for entry in data:
        results = entry.get('results', {})
        snr = results.get('SNR')
        cer = results.get('CER (Frame Error Rate)')
        if snr is not None and cer is not None and cer != '':
            # Remove ' dB' and convert to float
            snrs.append(float(snr.replace(' dB','')))
            cers.append(float(cer))
    return np.array(snrs), np.array(cers)

def main():
    # Add more datasets here as needed
    datasets = [
        {
            'json': 'full_sova_simulations.json',
            'label': 'Full protection mode (AWGN)',
            'color': 'deepskyblue',
            'linestyle': '--', # - for solid line, '--' for dashed
            'marker': 'x',
        },
        {
            'json': 'full_1d_simulations.json',
            'label': '1D RS(200, 168)',
            'color': 'deepskyblue',
            'linestyle': '--', # - for solid line, '--' for dashed
            'marker': 'x',
        },
        # Add more dicts for other modes if you have more JSONs
    ]

    plt.figure(figsize=(12,5))

    for ds in datasets:
        json_path = os.path.join(os.path.dirname(__file__), ds['json'])
        snrs, cers = load_results(json_path)
        plt.plot(snrs, cers, label=ds['label'], color=ds['color'], linestyle=ds['linestyle'], marker=ds['marker'], markersize=7, markeredgecolor='black', markerfacecolor='black')

    # 1e-9 target line
    plt.axhline(1e-9, color='red', linestyle='--', linewidth=3, label='1e-9 target')
    # Software simulation limit (example at 1e-6)
    plt.axhline(3.14e-6, color='gray', linestyle='--', linewidth=2, label='Software simulation limit')

    plt.yscale('log')
    plt.xlabel('SNR [dB]', fontsize=16)
    plt.ylabel('CER', fontsize=16)
    plt.xticks(fontsize=12)
    plt.yticks(fontsize=12)
    plt.xlim(14, 17.5)
    plt.ylim(1e-9, 1e0)
    # Only major grid lines, no minor log lines
    plt.grid(True, which='major', axis='y', linestyle='--', alpha=0.5)
    # Add vertical lines for each 0.1 SNR step
    for x in np.arange(14, 17.6, 0.1):
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
