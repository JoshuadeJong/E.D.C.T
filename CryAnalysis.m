function [] = CryAnalysis(DM3_File, MaxD, MinD)
% CryAnalysis takes a Dm3 image, identifies the particle and analyzes the
% orientation of the crystals forming the particle.
%
% Author: Joshua de Jong, Will Van Noordt
% Email: dejongjj@rams.colostate.edu, willvanzero@gmail.com
% Date: 6/19/2018
% Version: 1.3

InputAmount = 3;

%% Check for correct toolboxs
    if ToolboxCheck == 0
       return; 
    end

%% Check if user gave input
    if nargin ~= InputAmount
       [DM3_File, MinD, MaxD] = InputAsk; 
    end

%% Find DM3 File
    % Find file
    baseFileName = DM3_File;
    folder = fileparts(which(baseFileName)); % Determine where the folder is
    fullFileName = fullfile(folder, baseFileName);

    if ~exist(fullFileName, 'file')
        % It doesn't exist in the current folder.
        % look on the search path.
        if ~exist(baseFileName, 'file')
            % If doesn't exist on the search path either.
            % Alert user that file can't be found
            title = 'CryAnalysis - File Error';
            warningMessage = sprintf('Error: the input file\n%s\n was not found. Click OK to exit.', fullFileName);
            uiwait(warndlg(warningMessage, title));
            fprintf(1, 'Finished running CryAnalysis.m\n');
            return;
        end
        
        fullFileName = baseFileName;
    end
    
        [~, ~, FileType] = fileparts(fullFileName);
    
    if strcmp(FileType, '.dm3')
    % Open DM3
        [m, sx, units] = ReadDMFile(fullFileName);

    % Convert to Png
        ms = single(m);
        msc=255*(ms-min(ms(:)))/max(ms(:)-min(ms(:)));
        Image = uint8(msc);
    elseif isPicture(fullFileName)
        Image = imread(fullFileName);
    else
        return
    end
    
%% Region Select
    Rec = [1, 1, size(Image,1)-1, size(Image,2)-1];
    [Rec, Option] = RegionInput(Image, Rec);
    Region = Image(Rec(2):Rec(2) + Rec(4), Rec(1):Rec(1) + Rec(3));
    
%% Locate Exact bounds of the Particle

if Option
    ImageBin = edge(Region, 'Sobel'); % edge detection
    
    ImageBin = bwareaopen(ImageBin, 4); % Remove 
    
    se = strel('square', 5);
    ImageBin = imdilate(ImageBin, se);
    
    ImageBin = bwareaopen(ImageBin, 50);
    
    BoundBW = bwconvhull(ImageBin);
        
    BoundBW = BoundBW == 0;
    
else 
    [RowI, ColumnI] = size(Image);
    
    BoundBW = zeros(RowI, ColumnI);
end
    
%% Divide Box up into 

    % Variables
    Coord = [1 1 size(Region)];
    Tolerance = 0;
    Depth = [MinD, MaxD];
    Depth_Count = 0;
    Data{1,1} = [0 0 0 0];
    Data{1,2} = -1;
    Data_Count = 0;
    
    
    [Data, Coord_Count] = FFT_Recursion(Region, BoundBW, Coord, Tolerance, Depth, Depth_Count, Data, Data_Count);  
    Image_Test = Region;
    
    
%% Color by Region
Data = Cluster(Data, Coord_Count);
    
%% Build BW, Polar, and Colored Region 

    % Build BW 
    Image_BW = Region;
    Image_BW(:,:) = 0;

    % Build RED, GREEN, BLUE
    RED_im = Image_BW;
    GRE_im = Image_BW;
    BLU_im = Image_BW;
    
    figure
    
    for k = 1:Coord_Count
        [RowS, ColumnS] = size(Data{k,2});
        
        if RowS == 0 || ColumnS == 0
            Image_Test = insertShape(Image_Test, 'Rectangle',...
                [Data{k,1}(2), Data{k,1}(1), Data{k,1}(4) - Data{k,1}(2), Data{k,1}(3) - Data{k,1}(1)],...
                'Color','red', 'LineWidth', 1);
    
        else
            Image_Test = insertShape(Image_Test, 'Rectangle',...
                [Data{k,1}(2), Data{k,1}(1), Data{k,1}(4) - Data{k,1}(2), Data{k,1}(3) - Data{k,1}(1)],...
                'Color','green', 'LineWidth', 1);
            
            Image_BW(Data{k,1}(1):Data{k,1}(3), Data{k,1}(2):Data{k,1}(4)) = 255;
            
            % find max Scalar
            [~, Index] = max(Data{k,2}(:,2));
            polarplot(Data{k,2}(Index,1), Data{k,2}(Index,2), 'b*')
            hold on
            
            Pos = Data{k,3}
            switch Pos
                case 1
                    RED_im(Data{k,1}(1):Data{k,1}(3),Data{k,1}(2):Data{k,1}(4)) = 1;
                case 2
                    RED_im(Data{k,1}(1):Data{k,1}(3),Data{k,1}(2):Data{k,1}(4)) = 1;
                    GRE_im(Data{k,1}(1):Data{k,1}(3),Data{k,1}(2):Data{k,1}(4)) = 1;
                case 3
                    GRE_im(Data{k,1}(1):Data{k,1}(3),Data{k,1}(2):Data{k,1}(4)) = 1;
                case 4
                    GRE_im(Data{k,1}(1):Data{k,1}(3),Data{k,1}(2):Data{k,1}(4)) = 1;
                    BLU_im(Data{k,1}(1):Data{k,1}(3),Data{k,1}(2):Data{k,1}(4)) = 1;
                case 5
                    BLU_im(Data{k,1}(1):Data{k,1}(3),Data{k,1}(2):Data{k,1}(4)) = 1;
                case 6
                    BLU_im(Data{k,1}(1):Data{k,1}(3),Data{k,1}(2):Data{k,1}(4)) = 1;
                    RED_im(Data{k,1}(1):Data{k,1}(3),Data{k,1}(2):Data{k,1}(4)) = 1;
            end
        end
    end

%% Post-process for Orientation
    RED_im2 = uint8(renormalize(dftgauss2(double(RED_im), 0.1, 0.1), 0, 160));
    GRE_im2 = uint8(renormalize(dftgauss2(double(GRE_im), 0.1, 0.1), 0, 160));
    BLU_im2 = uint8(renormalize(dftgauss2(double(BLU_im), 0.1, 0.1), 0, 160));
    
    GRAY = cat(3, Region, Region, Region);
    GRAY(:,:,1) = uint8(renormalize(double(GRAY(:, :, 1)) + double(RED_im2), 0, 255));
    GRAY(:,:,2) = uint8(renormalize(double(GRAY(:, :, 2)) + double(GRE_im2), 0, 255));
    GRAY(:,:,3) = uint8(renormalize(double(GRAY(:, :, 3)) + double(BLU_im2), 0, 255));
    
%% Post-process for FFT completeness
    
    imgreen = uint8(renormalize(dftgauss2(double(Image_BW), 0.1, 0.1), 0, 160));
    imgred = uint8(renormalize(dftgauss2(double(~Image_BW), 0.1, 0.1), 0, 160));   
    
    fullgray = cat(3, Region, Region, Region);
    fullgray(:,:,2) = uint8(renormalize(double(fullgray(:, :, 2)) + double(imgreen), 0, 255));
    fullgray(:,:,1) = uint8(renormalize(double(fullgray(:, :, 1)) + double(imgred), 0, 255));
    
    %% Figures
    

    figure
    imshow(Image_Test)
    figure
    imshow(Image_BW)
    figure
    imshow(fullgray)
    figure
    imshow(GRAY)
    
end

%% Functions
function [File, MinD, MaxD] = InputAsk()
    % Ask for inputs
    title = 'TEMWiz - Input';
    prompt = {'Enter DM3 or PNG file:', 'Min Recursion Depth', 'Max Recursion Depth'};
    dims = [1 70];
    definput = {'Crystal_Example.dm3 or Crystal_Example.png', '1', '8'};
    answer = inputdlg(prompt, title, dims, definput);

    % interpet inputs
    File = char(answer(1));
    MinD = str2num(char(answer(2)));
    MaxD = str2num(char(answer(3)));
end

function [Region] = RegionAuto(Image)

    [RowS, ColumnS, ~] = size(Image);
    PixelNum = RowS*ColumnS;

    % Constants
    HoleFill = 100;
    
    % Find Standard Deviation
    ImageBin = im2double(Image);
    MEAN = sum(sum(ImageBin))/PixelNum;
    ImageBin = (ImageBin - MEAN).^2;
    SD = sqrt(sum(sum(ImageBin))/PixelNum);
    
    % Find Binary Image
    ImageBin = ImageBin > .1*SD;
    
    % Romve Small Holes
    ImageBin = bwareaopen(ImageBin, HoleFill);
    ImageBin = ImageBin == 0;
    ImageBin = bwareaopen(ImageBin, HoleFill);
    ImageBin = ImageBin == 0;
        
    %Dilate ImageBin
    se = strel('square', 15);
    ImageBin = imdilate(ImageBin, se);
        
    % find Blob Info
    info = regionprops(ImageBin, Image, 'All');
    
    % Parse info
    AREAS = info.Area;
    BOXS = info.BoundingBox;
    
    % Find strongest AREA
    [~, Index] = max(AREAS);
    
    % Draw strongest Box
    ImageB = insertShape(Image, 'Rectangle', BOXS(Index,:), 'Color','green', 'LineWidth', 2);
    imshow(ImageB)
    
    % Ask if the user is happy with the bounding box
    Continue = questdlg('Do you want to keep selected region?', 'Continue', 'Yes', 'Change Region', 'Cancle');
        
    if strcmp(Continue,'Change Region')
        close(gcf)
        [BOXS] = RegionInput(Image, BOXS);
    else
        close(gcf)
    end
    
    Region = Image(BOXS(2):BOXS(2)+BOXS(4),BOXS(1):BOXS(1)+BOXS(3));
end

function [Rec, Option] = RegionInput(Image, Rec)

    %% Buttons
    f = figure('Visible', 'off', 'Position', [0 0 600 600]);
    axes('Units', 'pixels');
    imshow(Image);
    movegui(f,'center');
    
    uicontrol('Style', 'text',...
    'String', 'Select Region to Analys',...
    'Position', [240 550 120 20]);
    
    btn = uicontrol('Style', 'togglebutton',...
    'String', 'Done',...
    'Position', [430 50 60 25]);

    btn2 = uicontrol('Style', 'togglebutton',...
    'String', 'Cancel',...
    'Position', [500 50 60 25]);

    btn3 = uicontrol('Style', 'togglebutton',...
    'String', 'Redraw',...
    'Position', [360 50 60 25]);

    % Area Analysis Selection
    uicontrol('Style', 'text',...
    'String', 'Partical Option',...
    'Position', [50 50 120 20]);
    
    radio(1)  = uicontrol('Style', 'radiobutton',...
    'String', 'Yes',...
    'Position', [160 50 40 20],...
    'Callback', @myRadio,...
    'Value',    0);
    
    radio(2)  = uicontrol('Style', 'radiobutton',...
    'String', 'No',...
    'Position', [210 50 40 20],...
    'Callback', @myRadio,...
    'Value',    1);
    
    function myRadio(RadioH, EventData) %#ok<INUSD>
        if RadioH.Value == 1
            otherRadio = radio(radio ~= RadioH);
            set(otherRadio, 'Value', 0);
        else
            otherRadio = radio(radio ~= RadioH);
            set(otherRadio, 'Value', 1);
        end
    end
    
    f.Visible = 'on';

    %% Logic
    
    while ~btn.Value

        if btn3.Value
            Rec = getPosition(imrect);
            
            RegionPic = insertShape(Image, 'Rectangle', Rec, 'Linewidth', 2, 'Color', 'green');
            imshow(RegionPic)
            drawnow
            
            btn3.Value = 0;
        end

        if btn2.Value
           Rec = [1, 1, size(Image,1)-1, size(Image,2)-1];
           Option = 1;
           break
        end
        
        Option = radio(1).Value;
        
        pause(.0001)
    end  
    
    close(gcf)
    
end

function [Data, Coord_Count] = FFT_Recursion(Image, ImageBW, Coord, Tolerance, Depth, Depth_Count, Data, Coord_Count)
        
    if Depth_Count < Depth(2)
        
        Region = Image(Coord(1):Coord(3), Coord(2):Coord(4));
        RegionBW = ImageBW(Coord(1):Coord(3), Coord(2):Coord(4));
        
        if sum(sum(RegionBW)) > Tolerance || Depth_Count < Depth(1)% Region Fails
            % Increase Depth Counter
            Depth_Count = Depth_Count + 1;

            % Sub divide Region
            SubDiv
           
        else % Region Passes
            
            % Run Function
            % fft_smoothing ~ 0.009
            % sd_scale ~ 5
            % offset_tolerance ~ 10
            % px_area_minimum ~2
            Data_Temp = analyze_crystal_region(Region, 0.009, 5, 10, 2);
            
            
            % Updata Count
            Coord_Count = Coord_Count + 1;

            % Record Coord
            Data{Coord_Count, 1} = Coord;


            % Store Data
            Data{Coord_Count, 2} = Data_Temp;
        end
    end
    
    
    function SubDiv()
       % Sub divide Region

            XMid = floor((Coord(1) + Coord(3))/2);
            YMid = floor((Coord(2) + Coord(4))/2);

           [Data, Coord_Count] = FFT_Recursion(Image, ImageBW,...
                [Coord(1), Coord(2), XMid, YMid],...
                Tolerance, Depth, Depth_Count, Data, Coord_Count);

           [Data, Coord_Count] = FFT_Recursion(Image, ImageBW,...
                [XMid+1, Coord(2), Coord(3), YMid],...
                Tolerance, Depth, Depth_Count, Data, Coord_Count);

           [Data, Coord_Count] = FFT_Recursion(Image, ImageBW,...
                [Coord(1), YMid+1, XMid, Coord(4)],...
                Tolerance, Depth, Depth_Count, Data, Coord_Count);

           [Data, Coord_Count] = FFT_Recursion(Image, ImageBW,...
                [XMid+1, YMid+1, Coord(3), Coord(4)],...
                Tolerance, Depth, Depth_Count, Data, Coord_Count); 
    end
end

function [weighted_thetas] = analyze_crystal_region(Imageregion, fft_smoothing, sd_scale, offset_tolerance, px_area_minimum)
%%%%%%%%%%%%%%%%%%I/O%%%%%%%%%%%%%%%%%%%%%%%%
% Imageregion: grayscale data of a region of an image to analyze

% fft_smoothing: smoothing parameter for region fft

% sd_scale: standard deviation threshold for smoothed fft

% offset_tolerance: tolerance for dc offset detection

% px_area_minimum: minimal area (in pixels) of sd treshold region to be
% considered a present crystal structure

% RECCOMMENDED DEFAULT VALUES:
% fft_smoothing ~ 0.009
% sd_scale ~ 5
% offset_tolerance ~ 10
% px_area_minimum ~2

% get fft, make it nice
subfft_raw = fft2(Imageregion);
subfft_raw(1,1) = 0;
nice = rflip(dftgauss2(abs(subfft_raw), fft_smoothing, fft_smoothing));

% bin the nice fft
[n11, n22] = size(nice);
PixelNum = n11*n22;
nice = nice/PixelNum;
frameBin = nice;
MEAN = sum(sum(frameBin))/PixelNum;
frameBin = (frameBin - MEAN).^2;
SD = sqrt(sum(sum(frameBin))/PixelNum);
frameBin = frameBin > sd_scale*SD;

% do region calcs
labeledFrame = bwlabel(frameBin, 8);
blob_props = regionprops(labeledFrame, frameBin, 'all');
centroids = cat(1, blob_props.Centroid);
areas = cat(1, blob_props.Area);
if sum(areas) > 0
[centerx_2, centery_2] = size(frameBin);
centerx = centerx_2/2;
centery = centery_2/2;
center = [centery, centerx];
rels = centroids - center;
relmags = sqrt(rels(:, 1).^2 + rels(:, 2).^2);
[minmag, minindex] = min(relmags);

% perform region id
if minmag < offset_tolerance
    areas(minindex) = 0;
end
areas_log = areas > px_area_minimum;
new_roids_rel = [];
new_areas = [];
for i = 1:length(areas_log)
   if areas_log(i) == 1 && rels(i, 1) >= 0
       new_roids_rel = cat(1, new_roids_rel, [rels(i, 1), - rels(i,2)]);
       new_areas = cat(1, new_areas, areas(i));
   end
end

% calculate angles and average crystal orientation
thetas = zeros(1, length(new_areas));
for i = 1:length(new_areas)
    thetas(i) = atan((new_roids_rel(i, 2))/new_roids_rel(i,1));
end
thetas = thetas';
weights = new_areas;
weighted_thetas = cat(2, thetas, weights);
else
    weighted_thetas = [];
end
end

function [filtered] = dftgauss2(x, gamma_e1, gamma_e2)
[n1, n2] = size(x);
fx = fft2(x);
filter_kernal = zeros(n1,n2);
for i = 1:n1
   for j = 1:n2
       effective_i = i-1;
       effective_j = j-1;
       if i > n1/2
           effective_i = n1 - i;
       end
       if j > n2/2
           effective_j = n2 - j;
       end
       exponent = -((gamma_e1*effective_i)^2+(gamma_e2*effective_j)^2);
       filter_kernal(i,j) = fx(i,j)*exp(exponent);
   end
end
filtered = real(ifft2(filter_kernal));
end

function [corrected] = rflip(x)
[n1, n2] = size(x);
n1h = ceil(n1/2);
n2h = ceil(n2/2);
n2h1 = n2h+1;
n1h1 = n1h+1;
corrected11 = x(1:n1h, 1:n2h);
corrected12 = x(1:n1h, n2h1:n2);
corrected21 = x(n1h1:n1, 1:n2h);
corrected22 = x(n1h1:n1, n2h1:n2);
corrected = [corrected22, corrected21; corrected12, corrected11];
end

function [normalized] = renormalize(x, minv, maxv)
%%%%%%%%%%%%%%%%%%I/O%%%%%%%%%%%%%%%%%%%%%%%%
% x: matrix to be renormalized

% minv: lower limiting value for the new matrix

% maxv: upeer limiting value for the new matrix
a = x;
gmin = min(min(x));
gmax = max(max(x));
delta = maxv - minv;
gdelta = gmax - gmin;
[n1,n2] = size(x);
for i = 1:n1
    for j = 1:n2
       quotient = (a(i,j) - gmin)/gdelta;
       a(i,j) = minv + quotient*delta;
    end
end
normalized = a;
end

function [Data] = Cluster(Data, Coord_Count)
    
    for i = 1:Coord_Count
        
            [RowS, ColumnS] = size(Data{i,2});
        
        if RowS == 0 || ColumnS == 0
            Data{i,3} = -1;
        else

            [~, Index] = max(Data{i,2}(:,2));
            Pos = Data{i,2}(Index,1);

            if Pos < -pi/3
                Data{i,3} = 1; % RED
            elseif Pos < -pi/6
                Data{i,3} = 2; % RED GREEN
            elseif Pos < 0
                Data{i,3} = 3; % GREEN
            elseif Pos < pi/6
                Data{i,3} = 4; % GREEN BLUE
            elseif Pos < pi/3
                Data{i,3} = 5; % BLUE
            elseif Pos < pi/2 
                Data{i,3} = 6; % BLUE RED
            else
                Data{i,3} = 6;
            end
        end
    end
end