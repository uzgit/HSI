image_path = 'Tray001-1/capture/Tray001';

% Read image header info
info = read_envihdr(strcat(image_path, '.hdr'));

% Read .raw HSI image
image = multibandread(strcat(image_path, '.raw'), info.size, 'uint16',0, 'bil', 'ieee-le');

% Remove noisy bands and create reference sum
image = image(:,:, 10 : 200);
refsum = sum(image(1,1,:));

% Render original picture
figure, imagesc(image(:,:,1));

%Remove background
mask = ((sum(image, 3) - refsum) / 191) > 70;

% Remove objects smaller than 200 pixels
mask = bwareaopen(mask, 200);
image = image .* mask;


% *******************************************************
% * Locate each wood chip in the picture and extract it
% * into a Cell array, this means that we can free the
% * memory used by the hyperspectral image, the logic
% * bwimage and just index each cell to get a wood chip 
% *******************************************************
% Find bounding boxes around all the wood chips
s = regionprops(mask, 'BoundingBox');
Boxes = cat(1,s.BoundingBox);

% Create a Mx1 cell to hold all the wood chips 
% figure
C = cell(size(Boxes,1), 1);
for i = 1:size(Boxes,1)
    
    % Get the coordinates of the boxes
    starty = round(Boxes(i,1));
    stopy = starty+round(Boxes(i,3))-1;
    startx = round(Boxes(i,2));
    stopx = startx+round(Boxes(i,4))-1;
    
    % Create a 5x6 subplot and draw all the wood chips in the original image
    % for debugging
%     subplot(5,6,i),imagesc(image(startx:stopx,starty:stopy,1))
    
    % Store each woodchip into seperate cells
    C{i} = image(startx:stopx,starty:stopy,:);
end

% Clear variables
clear image startx starty stopx stopy boxes i mask Boxes refsum s SIZE mask;

% Create a 5x6 subplot and draw the wood chips in each cell to show that
% they are the same
figure
for i = 1:size(C,1)
    subplot(5,6,i),imagesc(C{i}(:,:,1))
end

%image = image.*mask;

%Remove rows
%image(all(all(image == 0,3),2),:,:) = [];
%Remove columns
%image(:,all(all(image == 0,3),1),:) = [];

