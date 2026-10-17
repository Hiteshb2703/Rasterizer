import numpy as np
import pandas as pd

# The exact sequences copied straight from your PDF
pn1_str = "0111110011111110100100101011101010100111000110010110011000101111011100100010000110101101000111100000100110110000101000000111011"
pn2_str = "1111110101010011001110111010010110001101111011010110110010010001110000101111100101011100110100010011110001010000110000010000001"
gold_str = "0011010001101100000110000100101110100010000001011001111000000000000111011001001110111010111011111100100001001100100111010110000"

# Convert strings to integer arrays
pn1 = np.array([int(b) for b in pn1_str])
pn2 = np.array([int(b) for b in pn2_str])
gold = np.array([int(b) for b in gold_str])

# Oscilloscope settings based on your screenshots[cite: 1]
fs = 5000               # Sample rate: 5 kS/s
num_samples = 200000    # Total rows required (200 kpts)
t_bit = 30.992 / 127    # Time per bit based on the cursor delta T

# Generate Time axis (from -16s to 24s to perfectly match the grid on the screen)
t = np.linspace(-16, 24, num_samples)

def generate_waveform(bit_sequence, t, t_bit):
    # Offset time to align the sequence properly
    t_shifted = t + 16 
    
    # Calculate which bit we are reading at each time step
    bit_indices = (t_shifted / t_bit).astype(int) % 127
    
    # Map binary 0/1 to 0V and 5V
    voltage = bit_sequence[bit_indices] * 5.0
    
    # Add a realistic amount of oscilloscope background noise
    noise = np.random.normal(0, 0.05, len(t))
    
    return voltage + noise

print("Generating pn1_000.csv...")
v_pn1 = generate_waveform(pn1, t, t_bit)
pd.DataFrame({'Time': t, 'Voltage': v_pn1}).to_csv('pn1_000.csv', index=False)

print("Generating pn2_000.csv...")
v_pn2 = generate_waveform(pn2, t, t_bit)
pd.DataFrame({'Time': t, 'Voltage': v_pn2}).to_csv('pn2_000.csv', index=False)

print("Generating gold_000.csv...")
v_gold = generate_waveform(gold, t, t_bit)
pd.DataFrame({'Time': t, 'Voltage': v_gold}).to_csv('gold_000.csv', index=False)

print("Done! All 3 files have been created in this folder.")