%
% Simple example how to transmit arbitrary signal using LimeSDR-USB
%
% Author:
%    Damir Rakhimov, CRL, TU Ilmenau, Dec 2019


clc
clear all

addpath('../_library') % add path with LimeSuite library 

% Initialize parameters
TotalTime   = 12;       % Time of observation, s
Fc          = 1003e6;   % Carrier Frequency, Hz
Fs          = 1e6;      % Frequency of sampling frequency, Hz
Ts          = 4e0;      % Signal duration, s
Fsig        = 0.5e0;    % Frequency of desired signal, Hz
Fdev        = 1e5;      % Frequency of deviation, Hz
Fif         = 2e5;      % Intermediate frequency, Hz
Asig        = 1;        % Amplitude of signal, V
BW          = 5e6;      % Bandwidth of the signal, Hz (5-40MHz and 50-130Mhz)
Gain        = 30;       % Receiver Gain, dB

% (1) Open a device handle:
dev = limeSDR(); % Open device

% (2) Setup device parameters. These may be changed while the device is actively streaming.
dev.tx0.frequency   = Fc;    % when set to 2450e6, samples are real, not complex.
dev.tx0.samplerate  = Fs;    % when set to 40e6, 50e6, overflow may occur.
dev.tx0.bandwidth   = BW;
dev.tx0.gain        = Gain;
dev.tx0.antenna     = 1;     % TX_PATH1

% (3) Read parameters from the device
Fs_dev      = dev.tx0.samplerate;  % in SPS
Fc_dev      = dev.tx0.frequency;
BW_dev      = dev.tx0.bandwidth;
Ant_dev     = dev.tx0.antenna;
Gain_dev    = dev.tx0.gain;
ChipTemp    = dev.chiptemp;
fprintf('Device sampling frequency: %3.1fHz, Initial sampling frequency: %3.1fHz\n', Fs_dev, Fs);
fprintf('Device carrier frequency: %3.1fHz, Initial carrier frequency: %3.1fHz\n', Fc_dev, Fc);
fprintf('Device bandwidth: %3.1fHz, Initial bandwith: %3.1fHz\n', BW_dev, BW);
fprintf('Device antenna: %d \n', Ant_dev);
fprintf('Device gain: %3.1fdB, Initial gain: %3.1fdB\n', Gain_dev, Gain);
fprintf('Device temperature: %3.1fC\n', ChipTemp);

% (4) Generate test signal
n           = 0:Fs_dev*Ts-1;
waveform    = Asig * exp(1i*2*pi*Fif/Fs_dev*n + 1i*Fdev/Fsig*sin(2*pi*Fsig/Fs_dev*n)); % signal with frequency modulation

% (5) Enable stream parameters. These may NOT be changed while the device is streaming.
dev.tx0.enable;

% (6) Calibrate TX channel
dev.tx0.calibrate;

% (7) Start the module
dev.start();
fprintf('Start LimeSDR\n');

% (8) Receive samples on RX0 channel
for idxLoop = 1:round(TotalTime/Ts)
    tic;
    dev.transmit(waveform);
    fprintf('Loading Time: %g\n', toc);
    status = dev.tx0.status;
    fprintf('Fifo size: %d\n', status.fifoFilledCount);
    pause(Ts-2*toc)
end
pause(1)

% (9) Cleanup and shutdown by stopping the RX stream and having MATLAB delete the handle object.
dev.stop();
clear dev;

fprintf('Stop LimeSDR\n');




