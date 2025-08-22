import sys
import re
import json
from datetime import datetime

def parse_log_file(log_file_path):
    with open(log_file_path, 'r') as file:
        log_lines = file.readlines()

    simulations = []
    current_simulation = None

    for line in log_lines:
        timestamp_match = re.match(r'\[(.*?)\]', line)
        if timestamp_match:
            timestamp = timestamp_match.group(1)
            message = line[timestamp_match.end():].strip()

            if "📈 Running simulation" in message:
                if current_simulation:
                    simulations.append(current_simulation)
                current_simulation = {
                    "timestamp": timestamp,
                    "results": {}
                }

            elif current_simulation:
                if "📊 Simulation" in message:
                    current_simulation["results"] = {}
                elif "SNR for simulation" in message:
                    snr_match = re.match(r'SNR for simulation \d+:\s+(.*)', message)
                    if snr_match:
                        current_simulation["results"]["SNR"] = snr_match.group(1)
                else:
                    key_value_match = re.match(r'(.*?):\s+(.*)', message)
                    if key_value_match:
                        key, value = key_value_match.groups()
                        if key in [
                            "Total Bits", "Bit Errors (Pre-FEC)", "Bit Errors (Post-FEC)",
                            "Total Frames", "Frame Errors", "BER (Pre-FEC)", "BER (Post-FEC)",
                            "CER (Frame Error Rate)", "Coding Gain"]:
                            current_simulation["results"][key] = value

    if current_simulation:
        simulations.append(current_simulation)

    return simulations

def save_to_json(simulations, output_file):
    with open(output_file, 'w') as file:
        json.dump(simulations, file, indent=4)

def main():
    if len(sys.argv) < 2:
        print("Usage: python parse.py <log_file_path>")
        sys.exit(1)

    log_file_path = sys.argv[1]
    output_file = "simulations.json"

    simulations = parse_log_file(log_file_path)
    save_to_json(simulations, output_file)

    print(f"Parsed simulations saved to {output_file}")

if __name__ == "__main__":
    main()