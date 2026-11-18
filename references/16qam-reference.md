# 16QAM Example Adapter

This adapter describes a real-passband, Gray-coded 16QAM teaching model. It is an example, not a restriction on the core skill.

## Signal chain

Four input bits form one symbol. Two bits select the I level and two bits select the Q level using Gray order `00, 01, 11, 10`. The unnormalized levels are `[-3, -1, +1, +3]`; dividing by `sqrt(10)` normalizes average symbol energy.

The passband signal is:

`s(t) = I(t) cos(2 pi fc t) - Q(t) sin(2 pi fc t)`

The receiver uses coherent local carriers, I/Q mixers, gain correction, rectangular matched filtering, threshold decisions at `[-2, 0, +2]/sqrt(10)`, and Gray inverse mapping.

## Baseline parameters

| Parameter | Value |
|---|---:|
| Bits | 8000 |
| Symbols | 2000 |
| Bits per symbol | 4 |
| Symbol rate | 200 Baud |
| Bit rate | 800 bit/s |
| Carrier | 2 kHz |
| Sample rate | 10 kHz |
| Samples per symbol | 50 |
| Baseline Eb/N0 | 10 dB |

The known local baseline is BER `14/8000 = 0.00175` and SER `14/2000 = 0.007` for the fixed-seed course model. A changed random seed or implementation can legitimately produce different finite-sample values.

## Figures

1. `01_input_bits.png`: source binary sequence and bit timing.
2. `02_tx_iq.png`: four-level normalized I and Q symbol waveforms.
3. `03_carrier.png`: real 2 kHz passband signal; I/Q changes appear as amplitude and phase changes.
4. `04_tx_constellation.png`: the ideal 4 by 4 transmit constellation.
5. `05_rx_constellation.png`: noisy received points and decision thresholds.
6. `06_recovered_iq.png`: transmitted symbols compared with matched-filter outputs.
7. `07_recovered_bits.png`: transmitted and recovered bits with error positions.
8. `08_ber_ser.png`: simulated BER/SER, theory, and finite-sample limits versus Eb/N0.

The top-level Simulink diagram is documentation, not a runtime metric figure.

## Teacher-facing facts

- Sixteen points come from four I levels times four Q levels; each symbol carries `log2(16)=4` bits.
- Cosine and sine carriers are 90 degrees apart, so coherent demodulation can separate I and Q over a symbol interval.
- Gray coding makes nearest-neighbor errors usually change one bit.
- The matched filter averages the 50 samples in a rectangular symbol and suppresses the unwanted high-frequency mixer term.
- BER counts wrong bits; SER counts wrong symbols, so one wrong symbol can produce multiple wrong bits.
- This teaching adapter uses known symbol-end sampling. Timing recovery and root-raised-cosine pulse shaping are possible extensions.
