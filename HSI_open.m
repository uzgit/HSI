% READ HYPERSPECTRAL CUBE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read header file
info = read_envihdr('Tray003-1/capture/Tray003-1.hdr');

% open raw image
image = multibandread('Tray003-1/capture/Tray003-1.raw', info.size , 'uint16', 0, 'bil', 'ieee-le');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% take away noisy bands
image = image(:,:, 10 : 200);


% BACKGROUND ELIMINATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% assume pixel (1,1) contains background spectra only
ref = image(1,1,:);

% create a corresponding reference matrix
reference_matrix = ones( [info.size(1:2) size(image, 3)] ) .* ref;

% determine similarity of each pixel to the reference (background) pixel at (1,1)
% determine vector difference
mask = image - reference_matrix;

% get scalar value for average element-wise difference
mask = abs(sum(mask, 3)) / 191;

% set values below a threshold to 0, values above a threshold to 1
mask = mask >= 80;

% filter considers all elements except center element
filter = [ 1 1 1  ;
           1 0 1  ;
           1 1 1 ];

buffer_distance = 3; %pixels
for i = 1 : buffer_distance
    % for each (x,y) location in the mask, get the sum of the 8 neighbors
    sums = conv2(mask, filter, 'same');
    
    % only keep pixels that are not touching background (sum == 8)
    mask = sums == 8;
end

% element-wise multiplication of image by mask in order to kill background pixels
image = image .* mask;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% FIND AND SORT CONNECTED COMPONENTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[labels, num_connected_components] = bwlabel(mask);
assert(num_connected_components == 30)

s = regionprops(labels, 'BoundingBox', 'Extrema', 'Centroid');
centroids = cat(1, s.Centroid);
x = round(centroids(:,1) / 200);
y = round(centroids(:,2) / 128);
[sorted, sort_order] = sortrows([y x]);
s2 = s(sort_order)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imshow(mask)
hold on
for k = 1:numel(s2)
   centroid = s2(k).Centroid;
   text(centroid(1), centroid(2), sprintf('(%d,%d)', idivide(int16(k-1), int16(5)) + 1, mod(k-1, 5) + 1), 'Color', 'red');
end
hold off

figure, imagesc(image(:,:,1));