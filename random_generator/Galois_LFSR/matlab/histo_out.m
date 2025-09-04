% =========================================================================
% File        : histo_out.m
% Author      : La Cesa Riccardo
% Date        : 29/08/2025
% Description : MATLAB script that takes the output of the random generator
%               from a txt file (binary strings, one per line) and plots
%               the histogram, processing the file in blocks.
% =========================================================================
clc; close all; clear;

% --- PARAMETERS ----------------------------------------------------------
filename  = '../testbench/data_out.txt';  % file path
buffer    = 1e5;                          % block line to read

% --- FILE OPENING --------------------------------------------------------
[fid, msg] = fopen(filename, 'r');
if fid < 0, error('Impossible to open %s: %s', filename, msg); end

% --- NUMBER OF BIT EXTRACTION --------------------------------------------

% first line extraction
first_line = fgetl(fid);

% number of bits
Nbits = numel(first_line);
nbins = 2^Nbits;

% Range
xmin = 0;
xmax = nbins - 1;

% Move file position pointer to beginning of open file
frewind(fid);

% --- HISTOGRAM ACCUMULATOR --------------------------------------------
counter = zeros(nbins, 1, 'uint64'); 

% --- BLOCK READ ---------------------------------------------------
endFile = false;

while ~endFile

    temp_val = zeros(buffer, 1);
    k = 0;

    for i = 1:buffer
        tline = fgetl(fid);
        % end file check
        if ~ischar(tline)
            endFile = true;                 
            break;
        end
        k = k + 1;
        temp_val(k) = bit2int(logical(tline(:)-'0'),Nbits);  
    end

    if k > 0
        temp_val = temp_val(1:k);  % cut empty lines at the end of the file
        block = accumarray(temp_val + 1, 1, [nbins, 1]);
        counter = counter + uint64(block);
    end
end

fclose(fid);

% --- PLOT ----------------------------------------------------------------
x = (0:nbins-1);
figure; 
bar(x, double(counter), 'BarWidth', 1); 
xlim([xmin xmax]);
grid on;
xlabel('Frequency');
ylabel('LFSR out');
title(sprintf('Histogram of %s (%d bit, %d bins)', filename, Nbits, nbins));


% --- INFO ----------------------------------------------------------------
tot = sum(counter);
fprintf('Read %s samples. Nbits = %d, nbins = %d.\n', string(tot), Nbits, nbins);
nnzcounter = nnz(counter);
fprintf('observed values: %d over %d (%.2f%%).\n', ...
        nnzcounter, nbins, 100*nnzcounter/nbins);

