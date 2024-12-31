%% Begin
% Title : MBVD fitting, calculated parameters from measured impedance: R0, C0, R1, L1, C1, Rs
% Author: Li En (488285848@qq.com) at Tsinghua University
% Date  : 2024-12-31
% Reference : Modified Butterworth-Van Dyke circuit for FBAR resonators and automated measurement system
% Larson J D, Bradley P D, Wartenberg S, et al. 
% [C]//2000 IEEE ultrasonics symposium. proceedings. an international symposium (Cat. No. 00CH37121). IEEE, 2000, 1: 863-868.

clear;
clc;
close all;
%% Custom initial data
% Define frequency range
f = 2000:1:8000; 

% Select six non-series or non-parallel resonance frequencies
selected_frequencies = [2600, 3200, 5600, 6200, 6800, 7400];

% Set file path, file format must be xlsx
% The first column is frequency (Hz), the second column is impedance magnitude (mag), and the third column is impedance angle (deg)
filename = "C:\Users\48828\Desktop\MBVD\MBVD.xlsx";  % Data file path


%% Extract data
% Import data
opts = detectImportOptions(filename, 'VariableNamingRule', 'preserve');
data = readtable(filename, opts);

% Extract frequency, impedance magnitude, and impedance angle
frequencies = data{:, 1};  % First column is frequency (Hz)
impedance = data{:, 2};  % Second column is impedance magnitude (mag)
impedance_angle = data{:, 3};  % Third column is impedance angle (deg)

% Calculate real part, imaginary part of impedance, and admittance magnitude
impedance_real = impedance.*cos(deg2rad(impedance_angle));  % Real part of impedance
impedance_imag = impedance.*sin(deg2rad(impedance_angle));  % Imaginary part of impedance
admittance = 1./impedance;  % Admittance magnitude

% Find the positions of these frequencies in the frequencies array
[~, idx_fre] = ismember(selected_frequencies, frequencies);

%% Calculate fs, fp, Qs0, Qp0, i.e., series resonance frequency, parallel resonance frequency, series resonance quality factor, parallel resonance quality factor
% Calculate frequency of maximum admittance fs
[~, idx_fs] = max(admittance);  % Find the index of the maximum admittance
fs = frequencies(idx_fs);  % fs is the frequency at the maximum admittance (Hz)

% Calculate frequency of maximum impedance fp
[~, idx_fp] = max(impedance);  % Find the index of the maximum impedance
fp = frequencies(idx_fp);  % fp is the frequency at the maximum impedance (Hz)

% Calculate 3dB bandwidth of admittance (based on maximum admittance)
Y_max = admittance(idx_fs);
Y_half_max = Y_max / sqrt(2);  % Half maximum value for 3dB bandwidth

% Find the frequency range where admittance drops to half maximum
% Find the first position where admittance drops to half maximum
bw_admittance_lower = find(admittance >= Y_half_max, 1, 'first');

% Find the second position where admittance drops to half maximum, ensuring that the bandwidth range is not affected by subsequent increases
bw_admittance_upper = find(admittance(bw_admittance_lower:end) <= Y_half_max, 1, 'first') + bw_admittance_lower - 1;

% Bandwidth calculation: the difference between the upper and lower frequencies
bw_fs = frequencies(bw_admittance_upper) - frequencies(bw_admittance_lower);  % 3dB bandwidth
Qs0 = fs / bw_fs;  % Series resonance quality factor Qs0

% Calculate 3dB bandwidth of impedance (based on maximum impedance)
Z_max = impedance(idx_fp);
Z_half_max = Z_max / sqrt(2);  % Half maximum value for 3dB bandwidth

% Find the frequency range where impedance drops to half maximum
bw_impedance_lower = find(impedance(idx_fs:end) >= Z_half_max, 1, 'first') + idx_fs - 1;
bw_impedance_upper = find(impedance(bw_impedance_lower:end) <= Z_half_max, 1, 'first') + bw_impedance_lower - 1;

% Bandwidth calculation: the difference between the upper and lower frequencies
bw_fp = frequencies(bw_impedance_upper) - frequencies(bw_impedance_lower);  % 3dB bandwidth
Qp0 = fp / bw_fp;  % Parallel resonance quality factor Qp0

% Display results
fprintf('Series resonance frequency fs = %.2f Hz\n', fs);
fprintf('Parallel resonance frequency fp = %.2f Hz\n', fp);
fprintf('Series resonance quality factor Qs0 = %.9f\n', Qs0);
fprintf('Parallel resonance quality factor Qp0 = %.9f\n', Qp0);

fprintf('Admittance bandwidth lower frequency: %.2f Hz\n', frequencies(bw_admittance_lower));
fprintf('Admittance bandwidth upper frequency: %.2f Hz\n', frequencies(bw_admittance_upper));
fprintf('Impedance bandwidth lower frequency: %.2f Hz\n', frequencies(bw_impedance_lower));
fprintf('Impedance bandwidth upper frequency: %.2f Hz\n', frequencies(bw_impedance_upper));


%% Calculate Rs_R0 and C0
% Extract corresponding real and imaginary parts of impedance
selected_impedance_real = impedance_real(idx_fre);
selected_impedance_imag = impedance_imag(idx_fre);
% Transpose selected_frequencies to column vector for multiplication with imaginary impedance
selected_frequencies = selected_frequencies(:);

% Calculate angular frequency
omega = 2 * pi * selected_frequencies;

% Calculate the value 1 / (omega * Z_imag) for each frequency
results = 1 ./ (omega .* selected_impedance_imag);

% Calculate the average value, which is the estimated capacitance C0
C0 = mean(results);
Rs_R0 = mean(selected_impedance_real); % Rs + R0

%% Calculate C1 and L1
r = 1/((fp/fs)^2-1);
C1 = C0/r;
L1 = 1/((2*pi*fs)^2*C1);


%% Calculate Rs, R0, and R1
R0_R1 = 1/(2*pi*fp*C1*Qp0); % R0 + R1
R1_Rs = 1/(2*pi*fs*C1*Qs0); % R1 + Rs

Rs = 0.5*(Rs_R0+(R1_Rs-R0_R1));
R0 = Rs_R0-Rs;
R1 = R0_R1-R0;

%% Display results
fprintf('Estimated resistance R0 = %.9f Ω\n', R0);
fprintf('Estimated capacitance C0 = %.9f F\n', C0);
fprintf('Estimated resistance R1 = %.9f Ω\n', R1);
fprintf('Estimated inductance L1 = %.9f H\n', L1);
fprintf('Estimated capacitance C1 = %.9f F\n', C1);
fprintf('Estimated resistance Rs = %.9f Ω\n', Rs);


%% Scan impedance and admittance magnitudes
% Define angular frequency for the frequency range
omega = 2 * pi * f;

% Calculate impedance components
Z_R0C0 = R0 + 1 ./ (1j * omega * C0);  % Series combination of R0 and C0
Z_R1L1C1 = R1 + 1j * omega * L1 + 1 ./ (1j * omega * C1);  % Series combination of R1, L1, and C1

% Parallel total impedance
Z_parallel = 1 ./ (1 ./ Z_R0C0 + 1 ./ Z_R1L1C1);

% Total impedance Z(f)
Z_total = Rs + Z_parallel;

% Calculate impedance magnitude
Z_abs = abs(Z_total);

% Calculate admittance magnitude
Y_abs = abs(1 ./ Z_total);  % Admittance is the reciprocal of impedance


%% Plot fitting curves
% Plot impedance magnitude and comparison with experimental data
figure;
% Plot Z_abs
plot(frequencies, Z_abs, 'r--', 'DisplayName', 'MBVD Fitting');  % Use red dashed line
hold on;
% Plot impedance
plot(frequencies, impedance, 'k-', 'DisplayName', 'Experimental Data');  % Use black solid line

xlabel('Frequency (Hz)');
ylabel('Impedance (Mag)');
legend show;
hold off;

% Plot admittance magnitude and comparison with experimental data
figure;
% Plot Y_abs
plot(frequencies, Y_abs, 'r--', 'DisplayName', 'MBVD Fitting');  % Use red dashed line
hold on;
% Plot admittance
plot(frequencies, admittance, 'k-', 'DisplayName', 'Experimental Data');  % Use black solid line

xlabel('Frequency (Hz)');
ylabel('Admittance (Mag)');
legend show;
hold off;


% Convert to dB
% Convert impedance magnitude and admittance magnitude to dB
Z_dB = 20 * log10(Z_abs);          % Convert impedance magnitude to dB
Y_dB = 20 * log10(Y_abs);          % Convert admittance magnitude to dB

% Plot impedance magnitude and comparison with impedance (in dB)
figure;
% Plot Z_dB
plot(frequencies, Z_dB, 'r--', 'DisplayName', 'MBVD Fitting');  % Use red dashed line
hold on;
% Plot impedance converted to dB
impedance_dB = 20 * log10(abs(impedance));  % Convert impedance to dB
plot(frequencies, impedance_dB, 'k-', 'DisplayName', 'Experimental Data');  % Use black solid line

xlabel('Frequency (Hz)');
ylabel('Impedance (dB)');
legend show;
hold off;

% Plot admittance magnitude and comparison with admittance (in dB)
figure;
% Plot Y_dB
plot(frequencies, Y_dB, 'r--', 'DisplayName', 'MBVD Fitting');  % Use red dashed line
hold on;
% Plot admittance converted to dB
admittance_dB = 20 * log10(abs(admittance));  % Convert admittance to dB
plot(frequencies, admittance_dB, 'k-', 'DisplayName', 'Experimental Data');  % Use black solid line
xlabel('Frequency (Hz)');
ylabel('Admittance (dB)');
legend show;
hold off;
%% End
