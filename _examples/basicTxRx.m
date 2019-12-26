%
% Simple example how to transmit and receive signals simultaneously using one LimeSDR-USB
%
% Author:
%    Damir Rakhimov, CRL, TU Ilmenau, Dec 2019


clc
clear all

addpath('../_library') % add path with LimeSuite library 

% Initialize parameters
TotalTime   = 12;       % Time of observation, s
Fc          = 1003e6;   % Carrier Frequency
Fs          = 1e6;      % Frequency of sampling frequency, Hz
Ts          = 4e0;      % Signal duration, s
Fsig        = 0.5e0;    % Frequency of desired signal, Hz
Fdev        = 1e5;      % Frequency of deviation, Hz
Fif         = 2e5;      % Intermediate frequency, Hz
Asig        = 1;        % Amplitude of signal, [-1,1]
BW          = 5e6;      % Bandwidth of the signal, Hz (5-40MHz and 50-130Mhz)
RxGain      = 20;       % Receiver Gain, dB
TxGain      = 30;       % Transmitter Gain, dB

% (1) Open a device handle:
dev = limeSDR(); % Open device

% (2) Setup device parameters. These may be changed while the device is actively streaming.
dev.tx0.frequency   = Fc;    % when set to 2450e6, samples are real, not complex.
dev.tx0.samplerate  = Fs;    % when set to 40e6, 50e6, overflow may occur.
dev.tx0.bandwidth   = BW;
dev.tx0.gain        = TxGain;
dev.tx0.antenna     = 1;     % TX_PATH1

dev.rx0.frequency   = Fc;
dev.rx0.samplerate  = Fs;
dev.rx0.bandwidth   = BW;
dev.rx0.gain        = RxGain;
dev.rx0.antenna     = 2;     % LNA_L

% (3) Read parameters from the devices
ChipTemp       = dev.chiptemp;

Fs_dev_tx      = dev.tx0.samplerate;  % in SPS
Fc_dev_tx      = dev.tx0.frequency;  
BW_dev_tx      = dev.tx0.bandwidth;
Ant_dev_tx     = dev.tx0.antenna;
TxGain_dev     = dev.tx0.gain;

Fs_dev_rx      = dev.rx0.samplerate;  % in SPS
Fc_dev_rx      = dev.rx0.frequency;  
BW_dev_rx      = dev.rx0.bandwidth;
Ant_dev_rx     = dev.rx0.antenna;
RxGain_dev    = dev.rx0.gain;

fprintf('Device temperature: %3.1fC\n', ChipTemp);

fprintf('Tx Device sampling frequency: %3.1fHz, Initial sampling frequency: %3.1fHz\n', Fs_dev_tx, Fs);
fprintf('Tx Device carrier frequency: %3.1fHz, Initial carrier frequency: %3.1fHz\n', Fc_dev_tx, Fc);
fprintf('Tx Device bandwidth: %3.1fHz, Initial bandwith: %3.1fHz\n', BW_dev_tx, BW);
fprintf('Tx Device antenna: %d \n', Ant_dev_tx);
fprintf('Tx Device gain: %3.1fdB, Initial gain: %3.1fdB\n', TxGain_dev, TxGain);

fprintf('Rx Device sampling frequency: %3.1fHz, Initial sampling frequency: %3.1fHz\n', Fs_dev_rx, Fs);
fprintf('Rx Device carrier frequency: %3.1fHz, Initial carrier frequency: %3.1fHz\n', Fc_dev_rx, Fc);
fprintf('Rx Device bandwidth: %3.1fHz, Initial bandwith: %3.1fHz\n', BW_dev_rx, BW);
fprintf('Rx Device antenna: %d \n', Ant_dev_rx);
fprintf('Rx Device gain: %3.1fdB, Initial gain: %3.1fdB\n', RxGain_dev, RxGain);

% (4) Generate test signal 
Nsampl      = Fs_dev_tx*Ts;
n           = 0:Nsampl-1;
waveform    = Asig * exp(1i*2*pi*Fif/Fs_dev_tx*n + 1i*Fdev/Fsig*sin(2*pi*Fsig/Fs_dev_tx*n)); % FM modulated signal

% (5) Create empty array for the received signal
bufferRx    = complex(zeros(TotalTime*Fs,1));

% (6) Enable stream parameters. These may NOT be changed while the device is streaming.
dev.tx0.enable;
dev.rx0.enable;

% (7) Calibrate TX and RX channels
dev.tx0.calibrate;
dev.rx0.calibrate;

% (8) Start the module
dev.start();
fprintf('Start of LimeSDR\n');
pause(0.1)

% (9) Receive samples on RX0 channel
indRx = 1;  % index of the last received sample
for idxLoop = 1:round(TotalTime/Ts)
    tic;
    dev.transmit(waveform);
    fprintf('Time for loading: %g\n', toc); loadtime = toc;
    if (Ts-2*loadtime) > 0
        while (Ts - toc - loadtime > Ts/8)
            [samples, ~, samplesLength] = dev.receive((Fs*Ts/8),0);
            bufferRx(indRx:indRx+samplesLength-1) = samples;
            indRx = indRx + samplesLength;
        end
    end
    
    statusRx 	= dev.rx0.status;
    statusTx 	= dev.tx0.status;
    fprintf('Tx Fifo size: %d\n', statusTx.fifoFilledCount);
    fprintf('Rx Fifo size: %d\n', statusRx.fifoFilledCount);
    
    if (Ts-toc-loadtime)>0
        pause(Ts-toc-loadtime)
    end
end
pause(1)
    
% (10) Cleanup and shutdown by stopping the RX stream and having MATLAB delete the handle object.
dev.stop();
clear dev;

fprintf('Stop of LimeSDR\n');

% (11) Plot spectrogram (Signal Processing Toolbox is required)
tic
figure(1)
spectrogram(bufferRx,2^12,2^10,2^12,'centered','yaxis')
fprintf('Time for visualisation: %g\n', toc);















