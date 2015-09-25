function [M] = windowvar(image, window_size, param)
% [M] = windowvariation(image, window_size)
% Usage: generate a matrix used to get the total varation for each pixel 
%	in a window centered at it.
% Input:
%	- image: original image
%	- window_size: half size of the window
%	- param
%	  	.mu 		[10] lightness weight in Lab color space
%	  	.ga 		[120] color-opponent weight in Lab color space
%	  	.sigma 		[0.5] lightness weight
% Ouput:
% 	- M: generated matrix (sparse)

if isfield(param, 'mu')
	mu = param.mu;
else
	mu = 10.0;
end

if isfield(param, 'ga')
	ga = param.ga;
else
	ga = 120.0;
end

if isfield(param, 'sigma')
	sigma = param.sigma;
else
	sigma = 0.5;
end

cform = makecform('srgb2lab');
image_lab = applycform(uint8(image),cform);
image_lab = double(image_lab);

height = size(image, 1); 
width = size(image,2);
pixel_num = height * width;

chrom = image_lab(:,:,1) / 100.0 ;
chrom_r = image_lab(:,:,2) / 220.0;
chrom_g = image_lab(:,:,3) / 220.0;

chrom = mu * chrom; chrom = chrom(:); % 10: best 
chrom_r = ga * chrom_r; chrom_r = chrom_r(:);
chrom_g = ga * chrom_g; chrom_g = chrom_g(:);

arr = 1:pixel_num;
f = @window;
temp_1 = repmat(window_size, 1, pixel_num); temp_2 = repmat(height, 1, pixel_num);
temp_3 = repmat(width, 1, pixel_num);
all_pair = arrayfun(f, arr, temp_1, temp_2, temp_3, 'UniformOutput', 0);
all_pair = cell2mat(all_pair');
pair_num = size(all_pair,1);

pair_1 = all_pair(:,1)'; pair_2 = all_pair(:,2)';
row = [1 : pair_num 1:pair_num];
col = [pair_1 pair_2];
val = [chrom(pair_1) - chrom(pair_2) ...
	   chrom_r(pair_1) - chrom_r(pair_2) ...
	   chrom_g(pair_1) - chrom_g(pair_2)];
tic;
val = sum(val.^2, 2);
val = exp(-sigma * val);
toc;
val = [val -1.0 * val];

row_1 = row + length(row) / 2; col_1 = col + pixel_num ;
row_2 = row_1 + length(row) / 2; col_2 = col_1 + pixel_num;
final_row = [row row_1 row_2];
final_col = [col col_1 col_2];
final_val = [val val val];
M = sparse(final_row, final_col, final_val);

function [win] = window(index, window_size, height, width)
row_index = mod(index, height);
col_index = floor(index / height) + 1;
p = row_index : min([height, row_index + window_size]);
q = col_index : min([width, col_index + window_size]);
[x,y] = meshgrid(p,q);
x = x(:); y = y(:);
id = (y-1) * height + x;
id = id(2:end); 
win = [index * ones(length(id),1) id];