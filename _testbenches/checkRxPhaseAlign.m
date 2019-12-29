%
% Example demonstrates phase difference between channels over frequencies
% one LimeSDR-USB and all channel
%
% Author:
%    Damir Rakhimov, CRL, TU Ilmenau, Dec 2019

clc
clear all

addpath('../_library')          % add path with LimeSuite library
addpath(genpath('../_tools'))   % add folder and subfolders with additional scripts to path
addpath('../_results')          % add path to folder with results



fprintf('====================== Script for evaluation of phase coherence between RX channels ====================== \n');
fprintf('%s - Current folder: "%s"\n',currTimeLine(),pwd);
filefolder_script  	= pwd; % to get path to current folder on the cluster
filefolder_result  	= sprintf('%s/../_results', filefolder_script);
savebool           	= true; % save results
plotbool = true; % plot figures


% Initialize parameters
TotalTime           = 4e0;     % Time of observation for one experiment, s
Fc                  = 900e6;    % Carrier Frequency, Hz5
Fs                  = 1e6;      % Frequency of sampling frequency, Hz
Ts                  = 0.5e0;    % Signal duration, s
Fdev                = 0.5e6;    % Frequency of deviation, Hz
Fi                  = 0.0e6;    % Intermediate frequency, Hz
Asig                = 1;        % Amplitude of signal, [-1,1]
BW                  = 5e6;      % Bandwidth of the signal, Hz (5-40MHz and 50-130Mhz)
RxGain              = 30;       % Receiver Gain, dB
TxGain              = 40;       % Transmitter Gain, dB
Nstat               = 10;       % number of experiments

phase_FD_stat       = zeros(Fs*Ts, Nstat);
sample_offset_all   = zeros(Nstat, 1);

for idxLoopStat = 1:Nstat
    fprintf('%s============================= Iteration #%d/%d ========================== \n',currTimeLine(),idxLoopStat,Nstat);
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
    
    dev.rx1.frequency   = Fc;
    dev.rx1.samplerate  = Fs;
    dev.rx1.bandwidth   = BW;
    dev.rx1.gain        = RxGain;
    dev.rx1.antenna     = 2;     % LNA_L
    
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
    RxGain_dev     = dev.rx0.gain;
    
    fprintf('Device temperature: %3.1fC\n', ChipTemp);

    fprintf('Tx Device antenna:  %1d \n', Ant_dev_tx);
    fprintf('Tx Device sampling frequency: %12.1fHz, \tInitial sampling frequency: %12.1fHz\n', Fs_dev_tx, Fs);
    fprintf('Tx Device carrier frequency:  %12.1fHz, \tInitial carrier frequency:  %12.1fHz\n', Fc_dev_tx, Fc);
    fprintf('Tx Device bandwidth:          %12.1fHz, \tInitial bandwith:           %12.1fHz\n', BW_dev_tx, BW);
    fprintf('Tx Device gain:               %12.1fdB, \tInitial gain:               %12.1fdB\n', TxGain_dev, TxGain);
    
    fprintf('Rx Device antenna:  %1d \n', Ant_dev_rx);
    fprintf('Rx Device sampling frequency: %12.1fHz, \tInitial sampling frequency: %12.1fHz\n', Fs_dev_rx, Fs);
    fprintf('Rx Device carrier frequency:  %12.1fHz, \tInitial carrier frequency:  %12.1fHz\n', Fc_dev_rx, Fc);
    fprintf('Rx Device bandwidth:          %12.1fHz, \tInitial bandwith:           %12.1fHz\n', BW_dev_rx, BW);
    fprintf('Rx Device gain:               %12.1fdB, \tInitial gain:               %12.1fdB\n', RxGain_dev, RxGain);
    
    % (4) Generate test chirp signal [-Fdev; Fdev] and cender at Fc+Fi
    Nsampl          = round(Fs_dev_tx*Ts);
    n               = 0:Nsampl-1;
    t               = n/Fs_dev_tx;
    waveform        = Asig * exp(1i*2*pi*Fi*t + 1i*2*pi*Fdev/(Ts/2)*( t.^2/2 - Ts/2*t )); % chirp waveform
    freqs           = Fdev/(Ts/2)*( t - Ts/2 );
    [~, FreqZind]   = min(abs(freqs)); % index of center frequency
    
    % (5) Create empty arrays for the received signals
    bufferRx0       = complex(zeros((TotalTime+Ts+1)*Fs,1));
    bufferRx1       = complex(zeros((TotalTime+Ts+1)*Fs,1));
    
    % (6) Enable stream parameters. These may NOT be changed while the device is streaming.
    dev.tx0.enable;
    dev.rx0.enable;
    dev.rx1.enable;
    
    % (7) Calibrate TX and RX channels
    dev.tx0.calibrate;
    dev.rx0.calibrate;
    dev.rx1.calibrate;
    
    % (8) Start the module
    dev.start(); fprintf('%s - LimeSDR Started\n', currTimeLine()); % pause(0.1)
    
    % (9) Transmit and Receive samples
    indRx0          = 1;  % index of the last received sample
    indRx1          = 1;
    TimeOut_ms      = 5000;
    Nskip          	= round(1*Fs_dev_rx); 
    TimeStamp_smpl  = Nskip; % Initial value for the TimeStamp
   
    for idxLoopRF   = 1:round(TotalTime/Ts)+1 % extra iteration to read all samples
        
        tic;
        if idxLoopRF <= round(TotalTime/Ts)
            dev.transmit(waveform, 0, TimeOut_ms, TimeStamp_smpl); % Before transmission skip 1e6 samples
            fprintf('\tSmpls written: %8d\t', Nsampl);
            fprintf('\tLoading time:  %7.4f\t', toc);
            TimeStamp_smpl = TimeStamp_smpl + Nsampl;
        else
            fprintf('\tSmpls written: %8d\t', 0);
            fprintf('\tLoading time:  %7.4f\t', toc);
        end
        
        continue_loop = true;
        while continue_loop
            tic
            statusRx0  	= dev.rx0.status;
            statusRx1  	= dev.rx1.status;
            [samples0, timestamp_out0, samplesLength0]  = dev.receive((statusRx0.fifoFilledCount), 0, TimeOut_ms);
            [samples1, timestamp_out1, samplesLength1]  = dev.receive((statusRx1.fifoFilledCount), 1, TimeOut_ms);
            bufferRx0(indRx0:indRx0+samplesLength0-1)   = samples0;
            bufferRx1(indRx1:indRx1+samplesLength1-1)   = samples1;
            indRx0    	= indRx0 + samplesLength0;
            indRx1    	= indRx1 + samplesLength1;
            statusTx0  	= dev.tx0.status;
            if idxLoopRF <= round(TotalTime/Ts)
                continue_loop	= (statusTx0.fifoFilledCount > 4e6);    % continue reception until decrease of Tx buffer
            else
                continue_loop   = (statusTx0.fifoFilledCount > 0);      % continue reception until empty Tx buffer
            end
            % fprintf('\ncontinue_loop:  %d\t', continue_loop);
            % fprintf('RX samples:     %d\t', samplesLength0);
            % fprintf('RX time:        %gs\n', toc);
        end

        if idxLoopRF > round(TotalTime/Ts)
            statusRx0 	= dev.rx0.status;
            statusRx1	= dev.rx1.status;
            [samples0, timestamp_out0, samplesLength0]  = dev.receive(statusRx0.fifoFilledCount + Fs*Ts/8, 0, TimeOut_ms);
            [samples1, timestamp_out1, samplesLength1]  = dev.receive(statusRx1.fifoFilledCount + Fs*Ts/8, 1, TimeOut_ms);
            bufferRx0(indRx0:indRx0+samplesLength0-1)   = samples0;
            bufferRx1(indRx1:indRx1+samplesLength1-1)   = samples1;
            indRx0      = indRx0 + samplesLength0;
            indRx1      = indRx1 + samplesLength1;
        end
        
        %if statusTx0.fifoFilledCount > 8000000
        %    pause(statusTx0.fifoFilledCount/(4*Fs_dev_tx));
        %end
        
        statusRx0       = dev.rx0.status;
        statusRx1       = dev.rx1.status;
        statusTx0       = dev.tx0.status;
        fprintf('\tTx0 Fifo size: %8d\t', statusTx0.fifoFilledCount);
        fprintf('\tRx0 Fifo size: %8d\t', statusRx0.fifoFilledCount);
        fprintf('\tRx1 Fifo size: %8d\t', statusRx1.fifoFilledCount);        
        fprintf('\tRx LinkRate:   %6.2fMB/s\n', max(statusRx0.linkRate,statusRx1.linkRate)/1e6);
    end
    
    fprintf('\tTotal number of samples from Rx0: %8d\t', indRx0-1);
    fprintf('\tTotal number of samples from Rx1: %8d\n', indRx1-1);
    
    % (10) Cleanup and shutdown by stopping the RX stream and having MATLAB delete the handle object.
    dev.stop(); clear dev; fprintf('%s - LimeSDR Stopped\n', currTimeLine());
    
    % (11) Process samples
    % calculate phase error between channels
    Nsampltotal     = Nsampl*round(TotalTime/Ts);
    %waveform_full 	= reshape(repmat(waveform.', 1,round(TotalTime/Ts)),[],1);
    %phase_orig      = unwrap(angle(waveform_full(1:Nsampltotal)));
    phase_rx0       = unwrap(angle(bufferRx0(1+Nskip:Nsampltotal+Nskip)));
    phase_rx1       = unwrap(angle(bufferRx1(1+Nskip:Nsampltotal+Nskip)));
    phase_diff     	= phase_rx0 - phase_rx1;
    phase_diff_mtx  = reshape(phase_diff, Nsampl, round(TotalTime/Ts));
    phase_diff_mtx  = unwrap(phase_diff_mtx,[],1);
    phase_diff_mtx  = phase_diff_mtx - phase_diff_mtx(FreqZind,:);
    % phase_FD        = unwrap(rem(mean(phase_diff_mtx,2),2*pi)); % phase difference between channels for different frequencies
    phase_FD        = mean(phase_diff_mtx,2);   % phase difference between channels for different frequencies
    phase_FD_stat(:,idxLoopStat) = phase_FD;   	% collect phases for different runs
    
    % calculate time offset between channels
    phase_FD_diff                   = diff(phase_FD);       % differentiate phase 
    sample_offset_all(idxLoopStat)	= -mean(phase_FD_diff(Ts/20*Fs:end-Ts/20*Fs,:),1)/(2*pi*Fdev)*(Ts/2*Fs_dev_rx*1*Fs_dev_rx);	% calculate time offset between channels
    % Time shift in TD will be linear phase in FD
    % x(t - 1/Fs*k) >> exp(-1i*2pi*Fdev/(T/2*Fs)*n*1/Fs*k)
    % n = 1 because we calculate phase difference between adjacent frequencies
end



% (12) Postprocessing
fprintf('%s============================== Postprocessing =========================== \n',currTimeLine());

% save variables
timestring 	= currTimeToStr();

if savebool == true % save file with workspace variables (.mat)
    filename_mat = sprintf('%s/checkRxPhaseAlign_%s_Fc=%s,Fs=%s,Fdev=%s,T=%d,Nstat=%d.mat', filefolder_result, timestring, num2sip(Fc_dev_rx,3), num2sip(Fs_dev_rx,3), num2sip(Fdev,3), TotalTime, Nstat);
    save(filename_mat, 'freqs', 'phase_FD_stat', 'Fc_dev_rx', 'Fs_dev_rx', 'Fdev', 'TotalTime', 'Ts', '-v7.3');
    fprintf('%s - Data saved to:    "%s"\n', currTimeLine(), filename_mat)
end

% process statistics
Nfreqhist           = 200; % number of frequencies on 2D histogram
FreqStep            = length(freqs)/Nfreqhist;
phase_FD_stat       = phase_FD_stat - phase_FD_stat(FreqZind,:);
phase_FD_stat_small = (reshape(phase_FD_stat.',[],Nfreqhist)).';


% (13) Plot results
if plotbool
    
    % Spectrogram (Signal Processing Toolbox is required)
    tic
    fig(1) = figure(1);
        subplot(2,1,1)
        spectrogram(bufferRx0,2^12,2^10,2^12,'centered','yaxis')
    subplot(2,1,2)
        spectrogram(bufferRx1,2^12,2^10,2^12,'centered','yaxis')
    fprintf('%s - Visualisation of Spectrogram:   %7.4fs\n', currTimeLine(), toc);

    % Received Signal
    tic
    fig(2) = figure(2);
    subplot(2,1,1)
        plot([real(bufferRx0(1:100:end));imag(bufferRx0(1:100:end))])
    subplot(2,1,2)
        plot([real(bufferRx1(1:100:end));imag(bufferRx1(1:100:end))])
    fprintf('%s - Visualisation of Signal:        %7.4fs\n', currTimeLine(), toc);

    % Phase (1 and 2) for each channel
    % Phase difference vs Frequency (3)
    tic
    fig(3) = figure(3);
    subplot(3,1,1)
        plot(phase_rx0(1:100:end))
        hold on
        plot(phase_rx1(1:100:end))
        hold off
    subplot(3,1,2)
        plot(radtodeg(rem(phase_diff(1:100:end), 2*pi)))
    subplot(3,1,3)
        plot(freqs, radtodeg(phase_FD_stat(:,end)));
    fprintf('%s - Visualisation of Phase Rx0-Rx1: %7.4fs\n', currTimeLine(), toc);

    % Histograms of phases for different frequencies
    tic
    fig(4)  = figure(4);
    bins   	= -200:0.1:200; % resolution of phase in histogram
    count  	= hist(radtodeg(phase_FD_stat_small.'), bins); % compute histograms
    b      	= bar3(bins, count); % plot as three-dimensional bar plot
    count   = 10*log10(count); % log scale of Z axis
    count(count==-Inf) = 0;
    [X,Y]   = meshgrid(freqs(1:FreqStep:end),bins);
    surf(X, Y, count,'linestyle','none'); view(2); colormap('jet')
    xlabel('Frequencies, Hz', 'FontSize',18)
    ylabel('Phase, deg', 'FontSize',18)
    zlabel('Count', 'FontSize',18)
    title('Phase difference vs Frequency', 'Fontsize', 22)
    colormap jet
    h = colorbar; ylabel(h,'10 log_{10}(Count)', 'FontSize',16)
    fprintf('%s - Visualisation of Histogram:     %7.4fs\n', currTimeLine(), toc);
    
    % Histograms of sample offset for different frequencies
    tic
    fig(5)  = figure(5);
    histogram(sample_offset_all,[-1:1/16:1]+1/32);
    xlabel('Sample offset, T_o/T_s', 'FontSize',18)
    ylabel('Count', 'FontSize',18)
    title('Histogram of Samples Offset', 'Fontsize', 22)
    fprintf('%s - Visualisation of Offsets:       %7.4fs\n', currTimeLine(), toc);
    
end


% (14) Save Plots 
if plotbool && savebool
 
    % Save 2D histogram
    filename_image = sprintf('%s/checkRxPhaseAlign_%s_hist_Fc=%s,Fs=%s,Fdev=%s,T=%d,Nstat=%d', filefolder_result, timestring, num2sip(Fc_dev_rx,3), num2sip(Fs_dev_rx,3), num2sip(Fdev,3), TotalTime, Nstat);
    set(fig(4),'PaperUnits','inches','PaperPosition',[0 0 7 4])
    %png
    print(filename_image,'-dpng','-r600' )
    %eps
    saveas(fig(4),filename_image,'epsc')
    fprintf('%s - Plot saved to:    "%s"\n', currTimeLine(), filefolder_result)

    % Save histograms of sample offset
    filename_image = sprintf('%s/checkRxPhaseAlign_%s_offset_Fc=%s,Fs=%s,Fdev=%s,T=%d,Nstat=%d', filefolder_result, timestring, num2sip(Fc_dev_rx,3), num2sip(Fs_dev_rx,3), num2sip(Fdev,3), TotalTime, Nstat);
    set(fig(5),'PaperUnits','inches','PaperPosition',[0 0 7 4])
    %png
    print(filename_image,'-dpng','-r600' )
    %eps
    saveas(fig(5),filename_image,'epsc')
    fprintf('%s - Plot saved to:    "%s"\n', currTimeLine(), filefolder_result)    
    
    % Save all Figures
    filename_fig = sprintf('%s/checkRxPhaseAlign_%s_Fc=%s,Fs=%s,Fdev=%s,T=%d,Nstat=%d.fig', filefolder_result, timestring, num2sip(Fc_dev_rx,3), num2sip(Fs_dev_rx,3), num2sip(Fdev,3), TotalTime, Nstat);
    savefig(fig,filename_fig)
    fprintf('%s - Figures saved to: "%s"\n', currTimeLine(), filefolder_result)
end
