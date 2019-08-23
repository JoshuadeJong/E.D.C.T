function [AREA, Rec] = TornadoPulse(VideoFile, ViewVideo, FPS, CustomRegion, SdScale, HoleFill)
% TornadoPulse looks at a video file of a micro tornado and records
% information about the volume of the central mass.
%
% Author: Joshua de Jong
% Email: dejongjj@rams.colostate.edu
% Date: 6/19/2018
% Version: 1.6

% Patch Notes
% Switch order of SD select and Region Select
% Added Cropping Tool

InputAmount = 6;

if ToolboxCheck == 0
   return; 
end

%% Check if user gave enough inputs
    if nargin ~= InputAmount
        [VideoFile, ViewVideo, FPS, CustomRegion] = InputAsk;
    end

%% Find Video file
    % Find file
    baseFileName = VideoFile;
    folder = fileparts(which(baseFileName)); % Determine where the folder is
    fullFileName = fullfile(folder, baseFileName);

    if ~exist(fullFileName, 'file')
        % It doesn't exist in the current folder.
        % look on the search path.
        if ~exist(baseFileName, 'file')
            % If doesn't exist on the search path either.
            % Alert user that file can't be found
            title = 'Video2Pictures - File Error';
            warningMessage = sprintf('Error: the input file\n%s\n was not found. Click OK to exit.', fullFileName);
            uiwait(warndlg(warningMessage, title));
            fprintf(1, 'Finished running Video2Pictures.m\n');
            return;
        end
        fullFileName = baseFileName;
    end

    % Read in the movie
    mov = VideoReader(fullFileName);

%% Analysis Movie Setup
    % Data initialization
    AREA = 0;

    % Set frame number
    FrameNum = 1;

    % Info for blob border
    se = strel('square', 2);

    % Grab info from first frame
    thisFrame = readFrame(mov);

    [RowS, ColumnS, ColorChannels] = size(thisFrame); % Find info about size
    PixelNum = RowS*ColumnS;
    
%% Crop Select
    
    Crop = Crop_Func(thisFrame);
    thisFrame = thisFrame(Crop(1):Crop(3), Crop(2):Crop(4), :);

%% SDSCALE Select

    if nargin < 6 
        [SdScale, HoleFill] = SLIDER(thisFrame, se);
    end    
    
%% Region Select
        
    if CustomRegion == 1 && size(CustomRegion,2) ~= 4
        [Rec, X1, Y1, X2, Y2, CustomRegion] = RegionInput(thisFrame);
    end

        % Create the video player object.
    if ViewVideo == 1
        videoPlayer = vision.VideoPlayer('Position', [100 100 [ColumnS, RowS]+30]);
        videoPlayer2 = vision.VideoPlayer('Position', [100+ColumnS+50 100 [ColumnS, RowS]+30]);
    end
    
%% Run Video

while hasFrame(mov)
    % take time to set FPS for video
    tic
    
    % Convert to grayscale if needed 
    if ColorChannels > 1
        % Convert image to grayscale
        thisFrame = rgb2gray(thisFrame);
    end
    
    % Build Binary Image
    frameBin = im2double(thisFrame);
    MEAN = sum(sum(frameBin))/PixelNum;
    frameBin = (frameBin - MEAN).^2;
    SD = sqrt(sum(sum(frameBin))/PixelNum);
    
    frameBin = frameBin > SdScale*SD;
    %frameBin = imfill(frameBin, 'holes');
    frameBin = bwareaopen(frameBin, HoleFill);
    
    % Label image parts
    labeledFrame = bwlabel(frameBin, 8);
    
    % find blob regions
    blobMeasurements = regionprops(labeledFrame, thisFrame, 'all');
    Centroid = regionprops(labeledFrame, thisFrame, 'centroid');
    
    % record area and centriod of blobs
    AreaTemp = cat(1,blobMeasurements.Area);
    Coord = cat(1,blobMeasurements.Centroid);    
    AreaOut = -1;
    
    if CustomRegion == 1
        for i = 1:size(Coord,1)
            if Coord(i,1) >= X1 && Coord(i,1) <= X2 && Coord(i,2) >= Y1 && Coord(i,2) <= Y2 
                AreaOut = AreaTemp(i);
            end
        end
    else
        AreaOut = max(AreaTemp);
    end
    
    AREA = [AREA; AreaOut];
    
    % find boundaries around blobls
    boundaries = bwperim(frameBin, 8);
    boundaries = imdilate(boundaries, se);
    
    % Create color images out of boundaires
    [red, green, blue] = deal(255*uint8(boundaries));
    
    % Color boundaires correctly
    red(boundaries) = 0;
    green(boundaries) = 255;
    blue(boundaries) = 0;
    
    Centroids = cat(1, Centroid.Centroid);
    
    % Make boundaries an RGB image
    boundaries = cat(3, red, green, blue);
    
    % Combine boundaries, centroids and region
    boundaries = insertMarker(boundaries, Centroids,'+', 'color', 'r', 'size', 10);   
    
    if CustomRegion == 1
       boundaries = insertShape(boundaries, 'Rectangle', Rec, 'Linewidth', 1, 'Color', 'blue');
    end
    
    % display annotated video frame using video player
    if ViewVideo == 1
        step(videoPlayer, thisFrame);
        step(videoPlayer2, boundaries);
    end
    
    % Extract the next frame from movie
    thisFrame = readFrame(mov);
    thisFrame = thisFrame(Crop(1):Crop(3), Crop(2):Crop(4), :);
    
    % Update Frame Count
    FrameNum = FrameNum + 1;
    
    % Adjust FPS based off of run time per each frame
    pause(1/FPS - toc)  
end

AREA = AREA(2:end);

end

function [VideoFile, ViewVideo, FPS, CustomRegion] = InputAsk()
    % Ask for inputs
    title = 'VideoPulse - Input';
    prompt = {'Enter video file:','View Video:','Set Frames Per Second to:', 'Custom Region:'};
    dims = [1 70];
    definput = {'Tornado_Example.mp4', 'Yes or No', '24', 'Yes or No' };
    answer = inputdlg(prompt, title, dims, definput);

    % interpet inputs
    VideoFile = char(answer(1));

    if strcmp(char(answer(2)), '1') || strcmp(char(answer(2)), '0')
        ViewVideo = str2double(cell2mat(answer(2)));
    elseif strcmp(char(answer(2)), 'Yes') || strcmp(char(answer(2)), 'yes')
        ViewVideo = 1;
    else
        ViewVideo = 0;
    end

    FPS = str2double(cell2mat(answer(3)));

    if strcmp(char(answer(4)), '1') || strcmp(char(answer(4)), '0')
        CustomRegion = str2double(cell2mat(answer(4)));
    elseif strcmp(char(answer(4)), 'Yes') || strcmp(char(answer(4)), 'yes')
        CustomRegion = 1;
    else
        CustomRegion = 0;
    end
end

function [Rec, X1, Y1, X2, Y2, CustomRegion] = RegionInput(thisFrame)
    
    CustomRegion = 1;
    f = figure('Visible', 'off', 'Position', [0 0 600 600]);
    axes('Units', 'pixels');
    imshow(thisFrame);
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
    'Position', [100 50 60 25]);

    f.Visible = 'on';
    
    %% Logic
        
    [RowS, ColumnS, ~] = size(thisFrame);
    Rec = [1, 1, ColumnS, RowS];
    
    while ~btn.Value

        if btn3.Value
            Rec = getPosition(imrect);
            
            RegionPic = insertShape(thisFrame, 'Rectangle', Rec, 'Linewidth', 2, 'Color', 'blue');
            imshow(RegionPic)
            drawnow
            
            btn3.Value = 0;
        end
        
        pause(.0001)
        
        if btn2.Value
               Rec = [1, 1, RowS, ColumnS];
               CustomRegion = 0;
               break
        end
    end  
    
    close(gcf)
    
    X1 = Rec(1);
    X2 = Rec(3) + Rec(1);
    Y1 = Rec(2);
    Y2 = Rec(4) + Rec(2);
    
end

function [SdScale, HoleFill] = SLIDER(thisFrame, se)

    % Find Frame Size
    [RowS, ColumnS, ColorChannels] = size(thisFrame);
    PixelNum = RowS*ColumnS;

    
    %Create Figure
    f = figure('Visible', 'off', 'Position', [0 0 600 600]);
    movegui(f,'center');
    axes('Units', 'pixels');
    imshow(thisFrame);
    
    %% Push Button
    
    %Title
    uicontrol('Style', 'text',...
    'String', 'Select Sd Scale and HoleFill',...
    'Position', [240 550 160 20]);
    
    %Done Button
    btn = uicontrol('Style', 'togglebutton',...
        'String', 'Done',...
        'Position', [450 10 40 25]);
    
    % Slider Text - SD Scale
    txt = uicontrol('Style','text',...
        'Position',[200 70 200 25],...
        'String','SD Scale: 0');
    
    % Slider - SD Scale
    sld = uicontrol('Style', 'slider',...
        'Min',0,'Max',.5,'Value',0,...
        'Position', [200 55 200 25]); 
    
    % Slider Text - SD Scale
    txt2 = uicontrol('Style','text',...
        'Position',[200 25 200 25],...
        'String','HoleFill Value: 0');
    
    % Slider - SD Scale
    sld2 = uicontrol('Style', 'slider',...
        'Min',0,'Max',10000,'Value',5000,...
        'Position', [200 10 200 25]); 
        
    %Turn Figure On
    f.Visible = 'on';
    
    %% Logic
    
    % Convert to grayscale if needed 
    if ColorChannels > 1
        % Convert image to grayscale
        SdScaleFrame = rgb2gray(thisFrame);
    else
        SdScaleFrame = thisFrame;
    end
        
    while ~btn.Value
        
        % Update Values
        SdScale = sld.Value;
        HoleFill = floor(sld2.Value);
        
        % Build Binary Image
        frameBin = im2double(SdScaleFrame);
        MEAN = sum(sum(frameBin))/PixelNum;
        frameBin = (frameBin - MEAN).^2;
        SD = sqrt(sum(sum(frameBin))/PixelNum);
        
        frameBin = frameBin > SdScale*SD;
        frameBin = bwareaopen(frameBin, HoleFill);
        
        % find boundaries around blobls
        boundaries = bwperim(frameBin, 8);
        boundaries = imdilate(boundaries, se);

        % Create color images out of boundaires
        [red, green, blue] = deal(255*uint8(boundaries));

        % Color boundaires correctly
        red(boundaries) = 0;
        green(boundaries) = 255;
        blue(boundaries) = 0;

        % Make boundaries an RGB image
        boundaries = cat(3, red, green, blue);

        % show Info
        imshow(boundaries)
        drawnow
        
        % Update SD Score
        Str = sprintf('SD Scale: %f', SdScale);
        Str2 = sprintf('HoleFill Value: %d', HoleFill);
        set(txt, 'String', Str);
        set(txt2, 'String', Str2);
        
    end
    
    close(gcf)
    
end
  
function [Crop] = Crop_Func(thisFrame)

    %% Button
    f = figure('Visible', 'off', 'Position', [0 0 600 600]);
    movegui(f,'center');
    axes('Units', 'pixels');
    imshow(thisFrame);
    
    uicontrol('Style', 'text',...
    'String', 'Select Region to Crop',...
    'Position', [240 550 120 20]);
    
    btn = uicontrol('Style', 'togglebutton',...
    'String', 'Done',...
    'Position', [430 50 60 25]);

    btn2 = uicontrol('Style', 'togglebutton',...
    'String', 'Cancel',...
    'Position', [500 50 60 25]);

    btn3 = uicontrol('Style', 'togglebutton',...
    'String', 'Crop',...
    'Position', [100 50 60 25]);

    btn4 = uicontrol('Style', 'togglebutton',...
    'String', 'Preview',...
    'Position', [175 50 60 25]);

    f.Visible = 'on';
    
    %% Logic
    
    [RowS, ColumnS, ~] = size(thisFrame);
    Crop = [1, 1, RowS, ColumnS];
    RegionPic = thisFrame;

    while ~btn.Value

        if btn3.Value
            Rec = getPosition(imrect);
            Crop = floor([Rec(2), Rec(1), Rec(4)+Rec(2), Rec(3)+Rec(1)]);
            
            RegionPic = insertShape(thisFrame, 'Rectangle', Rec, 'Linewidth', 2, 'Color', 'red');
            imshow(RegionPic)
            drawnow
            
            btn3.Value = 0;
        end
        
        if btn4.Value
            
            RegionC = thisFrame(Crop(1):Crop(3), Crop(2):Crop(4), :);
            
            imshow(RegionC)
            drawnow
            
            pause(2)
           
            imshow(RegionPic)
            drawnow
            
            btn4.Value = 0;
        end
        
        pause(.0001)
        
        if btn2.Value
           Crop = [1, 1, RowS, ColumnS];
           close(f)
           break
        end
    end  
    
    close(f)

end