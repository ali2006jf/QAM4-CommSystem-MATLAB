clear , clc
%---------------------Parameters-------------------------
bits = randi([0 1], 1,50);  

bit_2 = reshape(bits ,2, []);%reshape

%-------------------Symbol Mapping----------------------
symbols = zeros(1, size(bit_2,2)); 
 for i = 1:size(bit_2,2)
     pair = bit_2(:,i);

    if isequal(pair, [0; 0])
        symbols(i) = 1 + 1j;
    elseif isequal(pair, [0; 1])
        symbols(i) = -1 + 1j;
    elseif isequal(pair, [1 ;0])
        symbols(i) = 1 - 1j;
    elseif isequal(pair, [1; 1])
        symbols(i) = -1 - 1j;
    end
 end
%----------------
I = real(symbols);
Q = imag(symbols);

 fc = 100;    %carrier Frequency
 fs = 1000;   %sampeling Frequency
 Ts = 1/fs;

samples_per_symbol = 20;
I_expanded = repelem(I, samples_per_symbol);
Q_expanded = repelem(Q, samples_per_symbol);
t = 0 : Ts :(length(I_expanded)-1)*Ts;

s = I_expanded .* cos(2*pi*fc*t)- Q_expanded .* sin(2*pi*fc*t);
%-----------------------------add noise-----------------------------------

SNR_db = 1;%DB
signal_power = mean(s.^2);
SNR = 10^(SNR_db/10);
noise_power = signal_power / SNR;
noise = sqrt(noise_power) * randn(size(s));
s_noisy = s + noise;

% -------------------- Demodulation --------------------

RecI = s_noisy .* cos(2*pi*fc*t);
RecQ = - s_noisy .* sin(2*pi*fc*t);

% FIR lowpass filter
f_cutoff = 120;
Wn = f_cutoff / (fs/2);
N = 50;  
b = fir1(N, Wn);
delay = N / 2;

filtered_I = 2 * filter(b, 1, RecI);
filtered_Q = 2 * filter(b, 1, RecQ);

filtered_I = filtered_I(delay+1:end);
filtered_Q = filtered_Q(delay+1:end);

% Sample at symbol centers
offset = floor(samples_per_symbol/2);
start = offset + 1;
sampled_I = filtered_I(start:samples_per_symbol:end);
sampled_Q = filtered_Q(start:samples_per_symbol:end);

% Cut to shortest common length
L = min([length(sampled_I), length(symbols)]);
sampled_I = sampled_I(1:L);
sampled_Q = sampled_Q(1:L);


Rbits = zeros(2,L);
% -------------------- Decision Logic --------------------
for k=1 :length(sampled_I)
    if sampled_I(k) > 0 && sampled_Q(k) > 0
        Rbits(:, k) = [0; 0];
    elseif sampled_I(k) < 0 && sampled_Q(k) > 0
        Rbits(:, k) = [0; 1];
    elseif sampled_I(k) < 0 && sampled_Q(k) < 0
        Rbits(:, k) = [1; 1];
    elseif sampled_I(k) > 0 && sampled_Q(k) < 0
        Rbits(:, k) = [1; 0];
    end
end

% -------------------- Plotting --------------------
Rbits = Rbits(:)';

disp(['Length of bits: ', num2str(length(bits))]);
disp(['Length of Rbits: ', num2str(length(Rbits(:)))]);
num_bits = min(length(bits), length(Rbits));
bits_trimmed = bits(1:num_bits);
Rbits_trimmed = Rbits(1:num_bits);

num_errors = sum(bits_trimmed ~= Rbits_trimmed);
BER = num_errors / num_bits;

disp(['Compared bits: ', num2str(num_bits)]);
disp(['Bit errors: ', num2str(num_errors)]);
disp(['BER: ', num2str(BER)]);

figure;
plot(real(symbols), imag(symbols), 'bo', 'MarkerSize', 10, 'LineWidth', 2)
hold on;
plot(sampled_I, sampled_Q, 'rx', 'MarkerSize', 8);
legend('Original Symbols','Received Samples');
grid on;
xlim([-2 2]); ylim([-2 2]);
xlabel('I'); ylabel('Q');
title(['Constellation (SNR = ', num2str(SNR_db), ' dB, BER = ', num2str(BER), ')']);
axis square;

figure;
subplot(2,1,1);
plot(filtered_I, 'b');
hold on;
plot(I_expanded , 'g');
title(['In-phase (SNR = ', num2str(SNR_db), ' dB)']);
subplot(2,1,2);
plot(filtered_Q, 'r');
hold on;
plot(Q_expanded , 'g');
title(['Quadrature (SNR = ', num2str(SNR_db), ' dB)']);

figure;
plot(s);
hold on;
plot(s_noisy)
 
figure;
plot(t, s, 'b'); hold on;
plot(t, s_noisy, 'r');
legend('Original Signal', 'Noisy Signal');
xlabel('Time (s)'); ylabel('Amplitude');
title(['Modulated Signal with AWGN (SNR = ', num2str(SNR_db), ' dB)']);
grid on;
