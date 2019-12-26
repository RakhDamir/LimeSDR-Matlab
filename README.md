# LimeSDR-Matlab

### General
This repository contains a wrapper for LimeSDR-USB drivers that allows to work from Matlab.
All necessary files for the wrapper is located in the folder "_library".
You can find basic examples for the usage of the library in the folder "_examples".
Code is updated to support the current version of LimeSuit(19.04).
Before starting, run `help limeSDR.build_thunk` to view instructions on how to have MATLAB build a Thunk file to use in conjunction with libLimeSuite.

### Prerequisites
1. Matlab
2. LimeSuite 19.04
2. Compatible compiler (VS++ is recommended)
3. LimeSDR-USB

### Installation
Steps for the successfull installation:
1. Check that the compatible compiler is installed and Matlab recongises it (`mex --setup`)
2. Check that the LimeSuite 19.04 is installed (you need LimeSuite.dll file)
3. Run from Matlab `limeSDR.build_thunk();`
4. Connect LimeSDR-USB
5. Run one of examples

### System configuration
Original system configuration:
1. Windows 10 Pro
2. Visual Studio Professional 2015 (compiler)
3. Matlab 2018a
4. LimeSDR-USB

### Known issues
Library for the Simulink was not modified and probably doesn't work.

### Reference
The code is based on the work from [Jockover](https://github.com/jocover/Simulink-MATLAB-LimeSDR)



# License #
This code is distributed under an [MIT License](LICENSE.MIT).
