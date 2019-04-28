%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Open the image.
image_path = 'Tray001-1/capture/Tray001';

% Read image header info
info = read_envihdr(strcat(image_path, '.hdr'));

% Read .raw HSI image
image = multibandread(strcat(image_path, '.raw'), info.size, 'uint16',0, 'bil', 'ieee-le');

% Remove noisy bands and create reference sum
image = image(:,:, 10 : 200);
refsum = sum(image(1,1,:));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Remove background.
mask = ((sum(image, 3) - refsum) / 191) > 70;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Remove presumed-noisy edge bands
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

% Remove objects smaller than 200 pixels
mask = bwareaopen(mask, 200);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find and sort connected components. Each connected component corresponds
% to a single sample.

[labels, num_connected_components] = bwlabel(mask);

% We have 30 samples in each image. Let's do a sanity check.
assert(num_connected_components == 30)

% Find and sort connected components.
region_properties = regionprops(labels, 'BoundingBox', 'Extrema', 'Centroid');
centroids = cat(1, region_properties.Centroid);
x = idivide(int16(centroids(:,1)), int16(200));
y = idivide(int16(centroids(:,2)), int16(128));
[sorted, sort_order] = sortrows([y x]);
region_properties = region_properties(sort_order);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Apply mask
image = image .* mask;

% *******************************************************
% * Locate each wood chip in the picture and extract it
% * into a Cell array, this means that we can free the
% * memory used by the hyperspectral image, the logic
% * bwimage and just index each cell to get a wood chip 
% *******************************************************
% Find bounding boxes around all the wood chips

% s = regionprops(mask, 'BoundingBox');
Boxes = cat(1, region_properties.BoundingBox);

% Create a Mx1 cell to hold all the wood chips 
% figure
C = cell(size(Boxes,1), 1);
for i = 1:size(Boxes,1)
    
    % Get the coordinates of the boxes
    starty = round(Boxes(i,1));
    stopy = starty+round(Boxes(i,3))-1;
    startx = round(Boxes(i,2));
    stopx = startx+round(Boxes(i,4))-1;
    
    % Store each woodchip into seperate cells
    C{i} = image(startx:stopx,starty:stopy,:);
end

% Clear variables
clear startx starty stopx stopy boxes i mask Boxes refsum s SIZE mask;

% Render original picture
figure, imagesc(image(:,:,1));
hold on
for i = 1:size(C,1)
   centroid = region_properties(i).Centroid;
   text(centroid(1), centroid(2), sprintf('(%d,%d)', idivide(int16(i-1), int16(5)) + 1, mod(i-1, 5) + 1), 'Color', 'black');
end
hold off

% Create a 6x5 subplot and draw the wood chips in each cell to show that
% they are the same
figure
for i = 1:size(C,1)
    subplot(6,5,i),imagesc(C{i}(:,:,1))
    title(sprintf('(%d,%d)', idivide(int16(i-1), int16(5)) + 1, mod(i-1, 5) + 1))
end