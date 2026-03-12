% read the raw data
T = readtable('slow_fast_slow_fast_5each.csv');
% separate the acceleration data
T_acc = T(T.data_type==0,{'time_us','value_1','value_2','value_3'}); 
T_acc = rmmissing(T_acc); % in case we have NaN values
% separate the rotation data
T_rot = T(T.data_type==1,{'time_us','value_1','value_2','value_3','value_4'});
T_rot = rmmissing(T_rot); % incase we have NaN values

%% clean and pre-process the data
start_time_acc = T_acc{1,"time_us"};
start_time_rot = T_rot{1,"time_us"};
% note to self: T(rows,vars) extracts into another table, T{rows,vars}
% extracts into an array/single value

% shift so that the first row has time 0
T_acc.time_us = T_acc.time_us - start_time_acc;
T_rot.time_us = T_rot.time_us - start_time_rot;

%% Acceleration data
time_acc = T_acc{:,"time_us"};
vec_acc = T_acc{:,{'value_1','value_2','value_3'}};

acc_mag = vecnorm(vec_acc,2,2);

% figure
% plot(vec_acc(:,1))
% title('X-axis Acceleration')
% figure
% plot(vec_acc(:,2))
% title('Y-axis Acceleration')
% figure
% plot(vec_acc(:,2))
% title('Z-axis Acceleration')
% figure
% plot(acc_mag)
% title('Acceleration Magnitude')
%% Rotation data
time_rot = T_rot{:,"time_us"};
vec_rot = T_rot{:,{'value_1','value_2','value_3','value_4'}};

% figure
% plot(vec_rot(:,1))
% title('W Quaternion')
% figure
% plot(vec_rot(:,2))
% title('i Quaternion')
% figure
% plot(vec_rot(:,3))
% title('j Quaternion')
% figure
% plot(vec_rot(:,4))
% title('k Quaternion')

%% linear phase FIR filter
% fs = 50; % what if data doesn't come at regular time intervals?
% fc = 2; % how do we choose a good cutoff frequency if we don't know how fast user paddles?
% order = 100;
% b = firls(order,[0 fc/(fs/2) fc/(fs/2) 1],[1 1 0 0]);
% a = 1;
%% butterworth filter for Z-acceleration
fs = 50; % what if data doesn't come at regular time intervals?
fc = 1; % how do we choose a good cutoff frequency if we don't know how fast user paddles?
order = 3;
[b, a] = butter(order, fc/(fs/2));

% our testing shows that butteworth filter produces better results than the
% FIR filter.

% we also varied the cutoff frequency and we found that a cutoff of 1Hz for
% a sampling rate of 50Hz gives the best results. However, we must consider
% how this will change depending on how fast or slow the user paddles. A 
% potential solutions for this challenge is adaptive filtering. 

% in addtion, we test different values for the filter order to determine
% the minimum filter order that will still give us accurate results. we
% want to make sure the delays are still acceptable for real-time
% processing.

% figure
% freqz(b,a)

acc_z_lp = filter(b,a,vec_acc(:,3));
% figure
% findpeaks(acc_z_lp)
% title('Peaks - Low Pass Filtered Z-axis Acceleration')
% 
% [pks, loc] = findpeaks(acc_z_lp);
% peak_count = length(pks)

%% Flipped Z-acceleration'
% threshold for how much a local maximum has to standout to be considered a
% peak
min_peak_prominence = 4;
% note: value of 5 misses the slower paddles (lower peaks)
% note: value of 3 catches the slower paddles but also included noise (2
% additional samples)
% value of 4 is perfect (for "slow_fast_slow_fast_5each" example)
% value of 4 is also good for "fast_slow_fast_slow_10each" example

figure
% subplot(2,1,1)
findpeaks(-acc_z_lp,'MinPeakProminence',min_peak_prominence)
title('Peaks - Low Pass Filtered Flipped Z-axis Acceleration')

[pks, loc] = findpeaks(-acc_z_lp,'MinPeakProminence',min_peak_prominence);
peak_count = length(pks)

%% butterworth filter for W Quaternion
% fs = 50; % what if data doesn't come at regular time intervals?
% fc = 1; % how do we choose a good cutoff frequency if we don't know how fast user paddles?
% order = 3;
% [b, a] = butter(order, fc/(fs/2));
% 
% q_w_lp = filter(b,a,vec_rot(:,1));
% subplot(2,1,2)
% findpeaks(q_w_lp)
% title('Peaks - Low Pass Filtered W Quaternion')
% 
% [pks, loc] = findpeaks(q_w_lp);
% peak_count = length(pks)

% we will implement more advanced and robust techniques for detecting peaks
% for collecting stroke count. For example, Farahabadi et al. proposed a 
% combination of the Hilbert and Wavelet transforms alongside adaptive 
% thresholding.

% also, we could test a dynamic thresholding technique where peaks only
% qualify as peaks if its value exceeds a certain percentage of the moving
% average of the values of the last X number of peaks.

% we could also have a check for the delay between 2 peaks, and use that to
% eliminate 2 peaks that are physically impossible for a human rower to 
% produce.

% we could also check the difference between the peak and subsequent trough 
% values.