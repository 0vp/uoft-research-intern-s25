#!/usr/bin/env python3
"""
SNR Analysis Results Parser and Plotter
Generates professional BER/SER vs SNR plots from test results
"""

import os
import json
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.ticker import LogLocator, LogFormatter
from scipy.optimize import curve_fit
from scipy.interpolate import interp1d
import warnings
import re

def load_snr_results():
    """Load all SNR test results from logs directory"""
    logs_dir = './logs'
    results = {}
    
    if not os.path.exists(logs_dir):
        print(f"Directory {logs_dir} not found")
        return results
    
    for filename in os.listdir(logs_dir):
        if filename.startswith('snr_sweep_') and filename.endswith('.log'):
            filepath = os.path.join(logs_dir, filename)
            
            try:
                with open(filepath, 'r') as f:
                    data = json.load(f)
                
                # Extract key information
                pam_level = data['pam_level']
                n, k = data['rs_code']
                config = data['config']
                
                # Create unique key for this test configuration
                key = f"{pam_level}PAM_RS{n}_{k}_{config}"
                
                if key not in results:
                    results[key] = {
                        'pam_level': pam_level,
                        'rs_code': (n, k),
                        'config': config,
                        'snr_db': [],
                        'ser_mean': [],
                        'ber_mean': [],
                        'ser_std': [],
                        'ber_std': [],
                        'metadata': data['metadata']
                    }
                
                # Extract results
                for result in data['results']:
                    results[key]['snr_db'].append(result['snr_db'])
                    results[key]['ser_mean'].append(result['ser_mean'])
                    results[key]['ber_mean'].append(result['ber_mean'])
                    results[key]['ser_std'].append(result['ser_std'])
                    results[key]['ber_std'].append(result['ber_std'])
                
                print(f"Loaded: {filename} -> {key}")
                    
            except Exception as e:
                print(f"Error reading {filename}: {e}")
    
    return results

def create_professional_plots(results, save_plots=True):
    """Create professional BER/SER vs SNR plots"""
    
    if not results:
        print("No results to plot")
        return
    
    # Create figs directory
    os.makedirs('./figs', exist_ok=True)
    
    # Group results by PAM level and RS code for better plotting
    grouped_by_pam = {}
    grouped_by_rs = {}
    
    for key, data in results.items():
        pam_level = data['pam_level']
        rs_code = data['rs_code']
        
        # Group by PAM level
        if pam_level not in grouped_by_pam:
            grouped_by_pam[pam_level] = {}
        grouped_by_pam[pam_level][key] = data
        
        # Group by RS code
        rs_key = f"RS{rs_code[0]}_{rs_code[1]}"
        if rs_key not in grouped_by_rs:
            grouped_by_rs[rs_key] = {}
        grouped_by_rs[rs_key][key] = data
    
    # Create separate plots for each RS code
    for rs_key, rs_data in grouped_by_rs.items():
        n, k = list(rs_data.values())[0]['rs_code']  # Get N,K from first entry
        
        # Plot 1: BER vs SNR for this specific RS code
        plt.figure(figsize=(12, 8))
        
        colors = ['blue', 'red', 'green', 'orange', 'purple', 'brown']
        markers = ['o', 's', '^', 'D', 'v', '<']
        linestyles = ['-', '--', '-.', ':']
        
        plot_idx = 0
        
        # Sort by PAM level for consistent ordering
        sorted_keys = sorted(rs_data.keys(), key=lambda x: rs_data[x]['pam_level'])
        
        for key in sorted_keys:
            data = rs_data[key]
            pam_level = data['pam_level']
            snr_db = np.array(data['snr_db'])
            ber_mean = np.array(data['ber_mean'])
            ber_std = np.array(data['ber_std'])
            
            # Filter out zero BER values for log plot (replace with small value)
            ber_plot = np.maximum(ber_mean, 1e-15)
            
            color = colors[plot_idx % len(colors)]
            marker = markers[plot_idx % len(markers)]
            linestyle = linestyles[plot_idx % len(linestyles)]
            
            # Plot with error bars
            plt.errorbar(snr_db, ber_plot, yerr=ber_std, 
                        color=color, marker=marker, linestyle=linestyle,
                        linewidth=2, markersize=6, capsize=3,
                        label=f"{pam_level}-PAM + FFE+DFE + RS({n},{k})")
            
            plot_idx += 1
        
        # Configure plot to match Meta FEC style
        plt.yscale('log')
        plt.xlabel('SNR = V_pk²/σ² (dB)', fontsize=12, fontweight='bold')
        plt.ylabel('BER (log₁₀)', fontsize=12, fontweight='bold')
        plt.title(f'BER vs SNR with FFE+DFE Equalization - RS({n},{k})\n(Peak Power Normalized)', fontsize=14, fontweight='bold')
        plt.grid(True, alpha=0.3, which='both')
        plt.legend(fontsize=10, loc='upper right')
        
        # Set y-axis limits and ticks similar to Meta plot
        plt.ylim(1e-15, 1)
        plt.xlim(min([min(data['snr_db']) for data in rs_data.values()]) - 1,
                 max([max(data['snr_db']) for data in rs_data.values()]) + 1)
        
        # Format y-axis ticks to match Meta plot (0, -5, -10, -15)
        from matplotlib.ticker import FixedLocator, FuncFormatter
        
        # Set specific tick locations at powers of 10
        y_ticks = [1e0, 1e-5, 1e-10, 1e-15]  # 0, -5, -10, -15 on log scale
        y_labels = ['0', '-5', '-10', '-15']
        
        plt.gca().set_yticks(y_ticks)
        plt.gca().set_yticklabels(y_labels)
        
        # Add minor ticks between major ticks
        plt.gca().yaxis.set_minor_locator(LogLocator(base=10, subs=np.arange(2, 10) * 0.1, numticks=50))
        
        plt.tight_layout()
        
        if save_plots:
            plt.savefig(f'./figs/ber_vs_snr_RS{n}_{k}.png', dpi=300, bbox_inches='tight')
            print(f"Saved: ./figs/ber_vs_snr_RS{n}_{k}.png")
        
        # plt.show()
        
        # Plot 2: SER vs SNR for this specific RS code
        plt.figure(figsize=(12, 8))
        
        plot_idx = 0
        for key in sorted_keys:
            data = rs_data[key]
            pam_level = data['pam_level']
            snr_db = np.array(data['snr_db'])
            ser_mean = np.array(data['ser_mean'])
            ser_std = np.array(data['ser_std'])
            
            # Filter out zero SER values for log plot
            ser_plot = np.maximum(ser_mean, 1e-15)
            
            color = colors[plot_idx % len(colors)]
            marker = markers[plot_idx % len(markers)]
            linestyle = linestyles[plot_idx % len(linestyles)]
            
            plt.errorbar(snr_db, ser_plot, yerr=ser_std,
                        color=color, marker=marker, linestyle=linestyle,
                        linewidth=2, markersize=6, capsize=3,
                        label=f"{pam_level}-PAM + FFE+DFE + RS({n},{k})")
            
            plot_idx += 1
        
        plt.yscale('log')
        plt.xlabel('SNR = V_pk²/σ² (dB)', fontsize=12, fontweight='bold')
        plt.ylabel('SER (log₁₀)', fontsize=12, fontweight='bold')
        plt.title(f'SER vs SNR with FFE+DFE Equalization - RS({n},{k})\n(Peak Power Normalized)', fontsize=14, fontweight='bold')
        plt.grid(True, alpha=0.3, which='both')
        plt.legend(fontsize=10, loc='upper right')
        
        plt.ylim(1e-15, 1)
        plt.xlim(min([min(data['snr_db']) for data in rs_data.values()]) - 1,
                 max([max(data['snr_db']) for data in rs_data.values()]) + 1)
        
        # Format y-axis ticks to match Meta plot (0, -5, -10, -15)
        y_ticks = [1e0, 1e-5, 1e-10, 1e-15]  # 0, -5, -10, -15 on log scale
        y_labels = ['0', '-5', '-10', '-15']
        
        plt.gca().set_yticks(y_ticks)
        plt.gca().set_yticklabels(y_labels)
        
        plt.gca().yaxis.set_minor_locator(LogLocator(base=10, subs=np.arange(2, 10) * 0.1, numticks=50))
        
        plt.tight_layout()
        
        if save_plots:
            plt.savefig(f'./figs/ser_vs_snr_RS{n}_{k}.png', dpi=300, bbox_inches='tight')
            print(f"Saved: ./figs/ser_vs_snr_RS{n}_{k}.png")
        
        # plt.show()

def create_comparison_plot(results, save_plots=True):
    """Create a single plot comparing different configurations"""
    
    if not results:
        print("No results to plot")
        return
    
    plt.figure(figsize=(14, 10))
    
    # Create subplot for BER and SER
    plt.subplot(2, 1, 1)
    
    colors = ['blue', 'red', 'green', 'orange', 'purple', 'brown', 'pink', 'gray']
    markers = ['o', 's', '^', 'D', 'v', '<', '>', 'p']
    
    plot_idx = 0
    for key, data in sorted(results.items()):
        pam_level = data['pam_level']
        n, k = data['rs_code']
        snr_db = np.array(data['snr_db'])
        ber_mean = np.array(data['ber_mean'])
        
        # Filter out zero values for log plot (consistent with main plots)
        ber_plot = np.maximum(ber_mean, 1e-15)
        
        color = colors[plot_idx % len(colors)]
        marker = markers[plot_idx % len(markers)]
        
        plt.plot(snr_db, ber_plot, color=color, marker=marker, 
                linewidth=2, markersize=6, 
                label=f"{pam_level}-PAM RS({n},{k})")
        
        plot_idx += 1
    
    plt.yscale('log')
    plt.xlabel('SNR = V_pk²/σ² (dB)', fontsize=12, fontweight='bold')
    plt.ylabel('BER (log₁₀)', fontsize=12, fontweight='bold')
    plt.title('BER vs SNR Comparison - FFE+DFE Equalization\n(Peak Power Normalized)', fontsize=14, fontweight='bold')
    plt.grid(True, alpha=0.3, which='both')
    plt.legend(fontsize=9, loc='upper right')
    plt.ylim(1e-15, 1)
    
    # Format y-axis ticks to match Meta plot
    y_ticks = [1e0, 1e-5, 1e-10, 1e-15]
    y_labels = ['0', '-5', '-10', '-15']
    plt.gca().set_yticks(y_ticks)
    plt.gca().set_yticklabels(y_labels)
    
    # SER subplot
    plt.subplot(2, 1, 2)
    
    plot_idx = 0
    for key, data in sorted(results.items()):
        pam_level = data['pam_level']
        n, k = data['rs_code']
        snr_db = np.array(data['snr_db'])
        ser_mean = np.array(data['ser_mean'])
        
        # Filter out zero values for log plot (consistent with main plots)
        ser_plot = np.maximum(ser_mean, 1e-15)
        
        color = colors[plot_idx % len(colors)]
        marker = markers[plot_idx % len(markers)]
        
        plt.plot(snr_db, ser_plot, color=color, marker=marker,
                linewidth=2, markersize=6,
                label=f"{pam_level}-PAM RS({n},{k})")
        
        plot_idx += 1
    
    plt.yscale('log')
    plt.xlabel('SNR = V_pk²/σ² (dB)', fontsize=12, fontweight='bold')
    plt.ylabel('SER (log₁₀)', fontsize=12, fontweight='bold')
    plt.title('Symbol Error Rate vs SNR Comparison\n(Peak Power Normalized)', fontsize=14, fontweight='bold')
    plt.grid(True, alpha=0.3, which='both')
    plt.legend(fontsize=9, loc='upper right')
    plt.ylim(1e-15, 1)
    
    # Format y-axis ticks to match Meta plot
    y_ticks = [1e0, 1e-5, 1e-10, 1e-15]
    y_labels = ['0', '-5', '-10', '-15']
    plt.gca().set_yticks(y_ticks)
    plt.gca().set_yticklabels(y_labels)
    
    plt.tight_layout()
    
    if save_plots:
        plt.savefig('./figs/ber_ser_comparison.png', dpi=300, bbox_inches='tight')
        print("Saved: ./figs/ber_ser_comparison.png")
    
    # plt.show()

def print_summary(results):
    """Print a summary of the results"""
    print("\n" + "="*60)
    print("SNR ANALYSIS SUMMARY")
    print("="*60)
    
    for key, data in sorted(results.items()):
        pam_level = data['pam_level']
        n, k = data['rs_code']
        snr_db = data['snr_db']
        ber_mean = data['ber_mean']
        ser_mean = data['ser_mean']
        
        print(f"\n{pam_level}-PAM with RS({n},{k}):")
        print(f"  SNR range: {min(snr_db):.1f} - {max(snr_db):.1f} dB")
        
        # Find SNR for BER < 1e-3
        ber_threshold = 1e-3
        snr_for_ber = None
        for i, ber in enumerate(ber_mean):
            if ber <= ber_threshold:
                snr_for_ber = snr_db[i]
                break
        
        if snr_for_ber:
            print(f"  SNR for BER < 1e-3: {snr_for_ber:.1f} dB")
        else:
            print(f"  BER did not reach 1e-3 in tested range")
        
        # Find SNR for SER < 1e-3
        snr_for_ser = None
        for i, ser in enumerate(ser_mean):
            if ser <= ber_threshold:
                snr_for_ser = snr_db[i]
                break
        
        if snr_for_ser:
            print(f"  SNR for SER < 1e-3: {snr_for_ser:.1f} dB")
        else:
            print(f"  SER did not reach 1e-3 in tested range")
        
        # Show best performance
        min_ber = min(ber_mean)
        min_ser = min(ser_mean)
        max_snr = max(snr_db)
        
        print(f"  Best BER: {min_ber:.2e} at {max_snr:.1f} dB")
        print(f"  Best SER: {min_ser:.2e} at {max_snr:.1f} dB")

def fit_error_rate_curve(snr_db, error_rate, curve_type='complementary_erf'):
    """
    Fit a curve to error rate data (BER/SER vs SNR)
    
    Args:
        snr_db: SNR values in dB
        error_rate: BER or SER values
        curve_type: Type of curve to fit ('complementary_erf', 'sigmoid', 'exponential')
    
    Returns:
        fitted_curve_function, curve_parameters, r_squared
    """
    
    # Filter out zero values for fitting
    valid_mask = (error_rate > 0) & np.isfinite(error_rate) & np.isfinite(snr_db)
    if np.sum(valid_mask) < 4:  # Need at least 4 points for fitting
        return None, None, 0
    
    snr_fit = snr_db[valid_mask]
    error_fit = error_rate[valid_mask]
    
    try:
        if curve_type == 'complementary_erf':
            # Q-function approximation: typical for digital communications
            def qfunc_model(snr, a, b, c):
                return a * np.exp(-b * (snr - c)**2) + 1e-15
                
            # Initial guess
            p0 = [1.0, 0.1, np.mean(snr_fit)]
            popt, pcov = curve_fit(qfunc_model, snr_fit, error_fit, p0=p0, maxfev=5000)
            
            def fitted_func(snr):
                return qfunc_model(snr, *popt)
                
        elif curve_type == 'sigmoid':
            # Sigmoid model for steep transitions
            def sigmoid_model(snr, a, b, c, d):
                return a / (1 + np.exp(b * (snr - c))) + d
                
            p0 = [1.0, 1.0, np.mean(snr_fit), 1e-10]
            popt, pcov = curve_fit(sigmoid_model, snr_fit, error_fit, p0=p0, maxfev=5000)
            
            def fitted_func(snr):
                return sigmoid_model(snr, *popt)
                
        elif curve_type == 'exponential':
            # Simple exponential decay
            def exp_model(snr, a, b, c):
                return a * np.exp(-b * snr) + c
                
            p0 = [1.0, 0.5, 1e-10]
            popt, pcov = curve_fit(exp_model, snr_fit, error_fit, p0=p0, maxfev=5000)
            
            def fitted_func(snr):
                return exp_model(snr, *popt)
        
        # Calculate R-squared
        y_pred = fitted_func(snr_fit)
        ss_res = np.sum((error_fit - y_pred) ** 2)
        ss_tot = np.sum((error_fit - np.mean(error_fit)) ** 2)
        r_squared = 1 - (ss_res / ss_tot) if ss_tot > 0 else 0
        
        return fitted_func, popt, r_squared
        
    except Exception as e:
        print(f"Curve fitting failed: {e}")
        return None, None, 0

def create_comprehensive_plot(results, save_plots=True):
    """
    Create a comprehensive plot showing all BER and SER data with best-fit curves
    """
    
    if not results:
        print("No results to plot")
        return
    
    # Create a large figure with subplots
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(20, 16))
    
    # Define colors and styles for different configurations
    colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd', '#8c564b', '#e377c2', '#7f7f7f']
    markers = ['o', 's', '^', 'D', 'v', '<', '>', 'p']
    linestyles = ['-', '--', '-.', ':']
    
    plot_idx = 0
    fit_results = {}
    
    # Plot 1: All BER data with fitted curves
    ax1.set_title('All BER vs SNR with Curve Fits\n(Peak Power Normalized)', fontsize=16, fontweight='bold')
    
    for key, data in sorted(results.items()):
        pam_level = data['pam_level']
        n, k = data['rs_code']
        snr_db = np.array(data['snr_db'])
        ber_mean = np.array(data['ber_mean'])
        ber_std = np.array(data['ber_std'])
        
        color = colors[plot_idx % len(colors)]
        marker = markers[plot_idx % len(markers)]
        
        # Fit curve and plot (no raw data points, only smooth curves)
        fitted_func, popt, r_squared = fit_error_rate_curve(snr_db, ber_mean, 'sigmoid')
        if fitted_func is not None:
            snr_smooth = np.linspace(min(snr_db), max(snr_db), 100)
            ber_smooth = fitted_func(snr_smooth)
            ax1.plot(snr_smooth, np.maximum(ber_smooth, 1e-15), 
                    color=color, linestyle='-', linewidth=3, alpha=0.9,
                    label=f"{pam_level}-PAM RS({n},{k})")
            
            fit_results[f"{key}_BER"] = {'func': fitted_func, 'r_squared': r_squared}
        
        plot_idx += 1
    
    ax1.set_yscale('log')
    ax1.set_xlabel('SNR = V_pk²/σ² (dB)', fontsize=14, fontweight='bold')
    ax1.set_ylabel('BER (log₁₀)', fontsize=14, fontweight='bold')
    ax1.grid(True, alpha=0.3, which='both')
    ax1.legend(fontsize=10, loc='upper right')
    ax1.set_ylim(1e-15, 1)
    
    # Format y-axis ticks
    y_ticks = [1e0, 1e-5, 1e-10, 1e-15]
    y_labels = ['0', '-5', '-10', '-15']
    ax1.set_yticks(y_ticks)
    ax1.set_yticklabels(y_labels)
    
    # Plot 2: All SER data with fitted curves
    ax2.set_title('All SER vs SNR with Curve Fits\n(Peak Power Normalized)', fontsize=16, fontweight='bold')
    
    plot_idx = 0
    for key, data in sorted(results.items()):
        pam_level = data['pam_level']
        n, k = data['rs_code']
        snr_db = np.array(data['snr_db'])
        ser_mean = np.array(data['ser_mean'])
        ser_std = np.array(data['ser_std'])
        
        color = colors[plot_idx % len(colors)]
        marker = markers[plot_idx % len(markers)]
        
        # Fit curve and plot (no raw data points, only smooth curves)
        fitted_func, popt, r_squared = fit_error_rate_curve(snr_db, ser_mean, 'sigmoid')
        if fitted_func is not None:
            snr_smooth = np.linspace(min(snr_db), max(snr_db), 100)
            ser_smooth = fitted_func(snr_smooth)
            ax2.plot(snr_smooth, np.maximum(ser_smooth, 1e-15),
                    color=color, linestyle='-', linewidth=3, alpha=0.9,
                    label=f"{pam_level}-PAM RS({n},{k})")
            
            fit_results[f"{key}_SER"] = {'func': fitted_func, 'r_squared': r_squared}
        
        plot_idx += 1
    
    ax2.set_yscale('log')
    ax2.set_xlabel('SNR = V_pk²/σ² (dB)', fontsize=14, fontweight='bold')
    ax2.set_ylabel('SER (log₁₀)', fontsize=14, fontweight='bold')
    ax2.grid(True, alpha=0.3, which='both')
    ax2.legend(fontsize=10, loc='upper right')
    ax2.set_ylim(1e-15, 1)
    ax2.set_yticks(y_ticks)
    ax2.set_yticklabels(y_labels)
    
    # Plot 3: BER vs SER correlation
    ax3.set_title('BER vs SER Correlation', fontsize=16, fontweight='bold')
    
    plot_idx = 0
    for key, data in sorted(results.items()):
        pam_level = data['pam_level']
        n, k = data['rs_code']
        ber_mean = np.array(data['ber_mean'])
        ser_mean = np.array(data['ser_mean'])
        
        color = colors[plot_idx % len(colors)]
        marker = markers[plot_idx % len(markers)]
        
        # Filter out zero values
        valid_mask = (ber_mean > 0) & (ser_mean > 0)
        if np.sum(valid_mask) > 0:
            ax3.scatter(np.maximum(ser_mean[valid_mask], 1e-15), 
                       np.maximum(ber_mean[valid_mask], 1e-15),
                       color=color, marker=marker, s=60, alpha=0.7,
                       label=f"{pam_level}-PAM RS({n},{k})")
        
        plot_idx += 1
    
    ax3.set_xscale('log')
    ax3.set_yscale('log')
    ax3.set_xlabel('SER (log₁₀)', fontsize=14, fontweight='bold')
    ax3.set_ylabel('BER (log₁₀)', fontsize=14, fontweight='bold')
    ax3.grid(True, alpha=0.3, which='both')
    ax3.legend(fontsize=10)
    
    # Add diagonal reference line (BER = SER)
    ax3.plot([1e-15, 1], [1e-15, 1], 'k--', alpha=0.5, label='BER = SER')
    
    # Plot 4: SNR thresholds comparison
    ax4.set_title('SNR Thresholds for Target Error Rates', fontsize=16, fontweight='bold')
    
    target_bers = [1e-3, 1e-5, 1e-10]
    target_labels = ['10⁻³', '10⁻⁵', '10⁻¹⁰']
    
    configurations = list(sorted(results.keys()))
    x_pos = np.arange(len(configurations))
    width = 0.25
    
    for i, target_ber in enumerate(target_bers):
        snr_thresholds = []
        
        for key in configurations:
            data = results[key]
            snr_db = np.array(data['snr_db'])
            ber_mean = np.array(data['ber_mean'])
            
            # Find SNR for target BER
            snr_threshold = None
            for j, ber in enumerate(ber_mean):
                if ber <= target_ber:
                    snr_threshold = snr_db[j]
                    break
            
            snr_thresholds.append(snr_threshold if snr_threshold else np.nan)
        
        # Remove NaN values for plotting
        valid_snr = [snr for snr in snr_thresholds if not np.isnan(snr)]
        valid_pos = [x_pos[j] + i*width for j, snr in enumerate(snr_thresholds) if not np.isnan(snr)]
        
        if valid_snr:
            ax4.bar(valid_pos, valid_snr, width, alpha=0.7, 
                   label=f'BER ≤ {target_labels[i]}')
    
    ax4.set_xlabel('Configuration', fontsize=14, fontweight='bold')
    ax4.set_ylabel('SNR Threshold (dB)', fontsize=14, fontweight='bold')
    ax4.set_xticks(x_pos + width)
    
    # Create shorter labels for x-axis
    short_labels = []
    for key in configurations:
        data = results[key]
        pam = data['pam_level']
        n, k = data['rs_code']
        short_labels.append(f"{pam}-PAM\\nRS({n},{k})")
    
    ax4.set_xticklabels(short_labels, rotation=45, ha='right')
    ax4.legend(fontsize=12)
    ax4.grid(True, alpha=0.3, axis='y')
    
    plt.tight_layout()
    
    if save_plots:
        plt.savefig('./figs/comprehensive_analysis.png', dpi=300, bbox_inches='tight')
        print("Saved: ./figs/comprehensive_analysis.png")
    
    # plt.show()
    
    # Print curve fitting summary
    print("\\n" + "="*60)
    print("CURVE FITTING SUMMARY")
    print("="*60)
    
    for key, fit_data in fit_results.items():
        r_squared = fit_data['r_squared']
        config_name = key.replace('_BER', '').replace('_SER', '')
        error_type = 'BER' if '_BER' in key else 'SER'
        
        print(f"{config_name} {error_type}: R² = {r_squared:.4f}")

def main():
    """Main function"""
    print("Loading SNR test results...")
    results = load_snr_results()
    
    if not results:
        print("No SNR test results found.")
        print("Run 'python tester.py [config]' to generate test data first.")
        return
    
    print(f"Found {len(results)} test configurations")
    
    # Print summary
    print_summary(results)
    
    # Create plots
    print("\nGenerating plots...")
    create_professional_plots(results)
    create_comparison_plot(results)
    
    # Create comprehensive plot with curve fitting
    print("\nGenerating comprehensive analysis with curve fitting...")
    create_comprehensive_plot(results)
    
    print("\nPlot generation completed!")
    print("Check the ./figs/ directory for generated plots.")
    print("  - Individual plots: ber_vs_snr_RSxx_xx.png, ser_vs_snr_RSxx_xx.png")
    print("  - Comparison plot: ber_ser_comparison.png")
    print("  - Comprehensive analysis: comprehensive_analysis.png")

if __name__ == "__main__":
    main()
