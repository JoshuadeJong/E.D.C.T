function [RGB, MaxData] = ColorSpec(FileName)
% ColorSpec Looks at the color spectrum of a area in a video or picture and
% records the data.
%
% Author: Joshua de Jong
% Email: dejongjj@rams.colostate.edu
% Date: 6/18/2018
% Version: 1.4

% Patch Notes
% Need to fix Watch video option
% Need to add align tool
 

%% Check if user has correct toolboxes
    if ToolboxCheck == 0
       return; 
    end

%% Check if user gave enough inputs
    if nargin < 1
        FileName = InputAsk;
    end

%% Find File
    FileName = FindFile(FileName);
    
%% If Video
    if isMovie(FileName)
        mov = VideoReader(FileName); %Read in Movie
        FrameNum = 1; % Set frame number
        thisFrame = readFrame(mov); % Grab first Frame
        [RowS, ColumnS] = size(thisFrame); % Find movie size
        
        [WATCH, FPS] = WatchAsk;
        
        if WATCH
            videoPlayer = vision.VideoPlayer('Position', [100 100 [ColumnS, RowS]+30]);
        end
        
        [Rec, X1, Y1, X2, Y2, Ori, Cut, Degree] = RegionInput(thisFrame);
        thisFrame  = imrotate(thisFrame, Degree);
        
        figure
        RGB = zeros(3,256);
        
        while hasFrame(mov)
            tic
                
            %Ceil 
            X1 = ceil(X1);
            X2 = ceil(X2);
            Y1 = ceil(Y1);
            Y2 = ceil(Y2);

            %Grab Region for color spectrum
            Region = thisFrame(Y1:Y2, X1:X2, :);
            
            % Area Analysis
            if Ori ~= 3
                [MaxDataTemp] = AreaAnalysis(Region, Ori, Cut);
                MaxData(:, :, FrameNum) = MaxDataTemp; %#ok<AGROW>
            else
                MaxData = 0;
            end
                            
            %Create histogram
            [RED, x] = imhist(Region(:,:,1));
            GRE = imhist(Region(:,:,2));
            BLU = imhist(Region(:,:,3));
            
            %Record Data
            RGB(1,:,FrameNum) = RED';
            RGB(2,:,FrameNum) = GRE';
            RGB(3,:,FrameNum) = BLU';
            
            %Place Rectangle into Frame
            thisFrame = insertShape(thisFrame, 'Rectangle', Rec, 'Linewidth', ceil(.005*(RowS + ColumnS)/2), 'Color', 'green');
            
            %Display Annotated Video
            if WATCH
                step(videoPlayer, thisFrame);
            end
                
            %Display Histogram
            plot(x, RED, 'r', x, GRE, 'g', x, BLU, 'b');
            
            % Extract the next frame from movie
            thisFrame = readFrame(mov);
            thisFrame  = imrotate(thisFrame, Degree);
    
            % Update Frame Count
            FrameNum = FrameNum + 1;
           
            % Adjust FPS based off of run time per each frame
            if WATCH
                pause(1/FPS - toc)
            end
        end
    end
    
%% If Picture
    if isPicture(FileName)
        Image = imread(FileName);
        [Rec, X1, Y1, X2, Y2, Ori, Cut, Degree] = RegionInput(Image);
        Image  = imrotate(Image, Degree);
        RGB = zeros(3,256);
        [RowS, ColumnS] = size(Image); % Find movie size
        
        %Ceil convert to integers
        X1 = ceil(X1);
        X2 = ceil(X2);
        Y1 = ceil(Y1);
        Y2 = ceil(Y2);
        
        %Grab Region for color spectrum
        Region = Image(Y1:Y2, X1:X2, :);
        
        if Ori ~= 3
            [MaxData] = AreaAnalysis(Region, Ori, Cut);
        end
        
        %Create RGB histogram
        [RED, x] = imhist(Region(:,:,1));
        GRE = imhist(Region(:,:,2));
        BLU = imhist(Region(:,:,3));

        %Record Data
        RGB(1,:) = RED';
        RGB(2,:) = GRE';
        RGB(3,:) = BLU';
        
        %Place Rectangle into Image
        Image = insertShape(Image, 'Rectangle', Rec, 'Linewidth', ceil(.005*(RowS + ColumnS)/2), 'Color', 'green');
        
        %Display Image
        figure
        imshow(Image)
        
        % Plot Histogram
        figure
        plot(x, RED, 'r', x, GRE, 'g', x, BLU, 'b');
        title('RGB Histogram')
        xlabel('RGB Value')
        ylabel('Number of Pixels')
        
    end

    %% Plot Max and Mean Data
    if isPicture(FileName)
        % Plot Max Data
        [~, ColumnS, ~] = size(MaxData);

        x = 1:ColumnS;
        figure
        plot(x, MaxData(1,:), 'r', x, MaxData(2,:), 'g', x, MaxData(3,:), 'b')
        
        if Ori == 1
            str = sprintf('Horizontal Cross Sections');
        elseif Ori == 2
            str = sprintf('Vertical Cross Sections');
        end
        
        title(str)
        xlabel('Slices Number')
        ylabel('RGB Value')
        drawnow
        
    else %Vert
        if Ori ~= 3
            for i = 1:3

                switch i
                    case 1; Color = 'Red';
                    case 2; Color = 'Green';
                    otherwise; Color = 'Blue';
                end

                % Plot max Data

                figure
                surf(squeeze(MaxData(i,:,:)));

                if Ori == 1
                    str = sprintf('Max %s Horizontal Cross Sections', Color);
                elseif Ori == 2
                    str = sprintf('Max %s Vertical Cross Sections', Color);
                end

                title(str);
                xlabel('Frames Number')
                ylabel('Slices Number')
                zlabel('RGB Value')

                drawnow
            end
        end
    end

end

% Functions
function [FileName] = InputAsk()
    % Ask for inputs
    title = 'ColorSpec - Input';
    prompt = {'Enter image or video file:'};
    dims = [1 70];
    definput = {'Dog_Example.jpg'};
    answer = inputdlg(prompt, title, dims, definput);

    % interpet inputs
    FileName = char(answer(1));
end

function [Rec, X1, Y1, X2, Y2, Ori, Cut, Degree] = RegionInput(Image)
    
    f = figure('Visible', 'off', 'Position', [0 0 600 600]);
    movegui(f,'center');
    axes('Units', 'pixels');
    imshow(Image);
    
    % Title Text
    uicontrol('Style', 'text',...
    'String', 'Select Region to Analys',...
    'Position', [240 550 120 20]);
    
    % Done Button
    btn = uicontrol('Style', 'togglebutton',...
    'String', 'Done',...
    'Position', [430 50 60 25]);
    
    % Cancle Button
    btn2 = uicontrol('Style', 'togglebutton',...
    'String', 'Cancel',...
    'Position', [500 50 60 25]);

    % Redraw Button
    btn3 = uicontrol('Style', 'togglebutton',...
    'String', 'Pick',...
    'Position', [360 50 60 25]);

    % Slice Type Text
    uicontrol('Style', 'text',...
    'String', 'Type of Slices',...
    'Position', [50 90 120 20]);
    
    % Slice Type Selection
    radio(1)  = uicontrol('Style', 'radiobutton',...
    'String', 'Horizontal',...
    'Position', [170 80 80 20],...
    'Callback', @myRadio,...
    'Value',    0);
    
    radio(2)  = uicontrol('Style', 'radiobutton',...
    'String', 'Vertical',...
    'Position', [250 80 60 20],...
    'Callback', @myRadio,...
    'Value',    0);

    radio(3)  = uicontrol('Style', 'radiobutton',...
    'String', 'Off',...
    'Position', [170 100 60 20],...
    'Callback', @myRadio,...
    'Value',    1);
    
    function myRadio(RadioH, EventData) %#ok<INUSD>
        if RadioH.Value == 1
            otherRadio = radio(radio ~= RadioH);
            set(otherRadio, 'Value', 0);
        else
            set(RadioH, 'Value', 1);
        end
    end

    %Slice Number Text
    uicontrol('Style', 'text',...
    'String', 'Slice size (Pixels)',...
    'Position', [50 50 120 20]);
    
    %Slice Number Enter
    edi = uicontrol('Style', 'edit',...
    'String', '10',...
    'Position', [170 50 60 25]);
    
    % Align button
    ali = uicontrol('Style', 'togglebutton',...
    'String', 'Align',...
    'Position', [360 90 60 25],...
    'Value', 0);

    % Make Ui visible
    f.Visible = 'on';
%% Logic

    Degree = 0;
    
    % Wait for user to finish
    while ~btn.Value

        if btn3.Value
            Rec = getPosition(imrect);
            
            RegionPic = insertShape(Image, 'Rectangle', Rec, 'Linewidth', 2, 'Color', 'green');
            imshow(RegionPic)
            drawnow
            
            btn3.Value = 0;
        end
        
        if ali.Value
            [Degree] = Align(Image);
            Image = imrotate(Image, Degree);
            imshow(Image)
            ali.Value = 0;
        end

        pause(.0001)
        
        if btn2.Value
           break
        end
    end  
    
    % Interp Data
    X1 = Rec(1);
    X2 = Rec(3) + Rec(1);
    Y1 = Rec(2);
    Y2 = Rec(4) + Rec(2);
    
    [~, Ori] = max([radio(1).Value, radio(2).Value, radio(3).Value]); % 1 if hor, 2 if vert, 3 if off
    
    Cut = floor(str2num(edi.String)); %#ok<ST2NM>
    
    % Close GUI
    close(gcf)
   
end

function [Degree] = Align(Image)

    
%% Buttons
    h = figure('Visible', 'off', 'Position', [0 0 600 600]);
    movegui(h,'center');
    axes('Units', 'pixels');
    imshow(Image);
    
    % Title Text
    uicontrol('Style', 'text',...
    'String', 'Select two points to align',...
    'Position', [200 550 200 20]);
    
    % Done Button
    btn = uicontrol('Style', 'togglebutton',...
    'String', 'Done',...
    'Position', [430 50 60 25]);
    
    % Cancle Button
    btn2 = uicontrol('Style', 'togglebutton',...
    'String', 'Cancel',...
    'Position', [500 50 60 25]);

    % Redraw Button
    btn3 = uicontrol('Style', 'togglebutton',...
    'String', 'Re-Align',...
    'Position', [100 50 60 25]);

    % View Button
    btn4 = uicontrol('Style', 'togglebutton',...
    'String', 'View',...
    'Position', [170 50 60 25]);

    % Make Ui visible
    h.Visible = 'on';
    
%% Logic

    % Set Align_Matrix
    Degree = 0; 
    RegionPic = Image;

    while ~btn.Value

        if btn3.Value
            Rec = getPosition(imline);
            
            if Rec(1,1) > Rec(2,1)
                Rec = [Rec(1,:), Rec(2,:)];
            else
                Rec = [Rec(2,:), Rec(1,:)];
            end
                
            RegionPic = insertShape(Image, 'Line', Rec, 'Linewidth', 2, 'Color', 'green');
            imshow(RegionPic)
            drawnow
            
           L1 = Rec(3) - Rec(1);
           L2 = Rec(4) - Rec(2);

           Degree = 180 + atan2d(L2,L1);
            
            btn3.Value = 0;
        end
        
        if btn4.Value
            Temp = imrotate(RegionPic, Degree);
            
            imshow(Temp);
            drawnow
            
            pause(2);
            
            imshow(RegionPic)
            drawnow
            
            btn4.Value = 0;
        end
        
        pause(.0001)
        
        if btn2.Value
           break
        end
        
    end  
    
    close(h)
    
end

function [WATCH, FPS] = WatchAsk()
    % Ask for inputs
    title = 'ColorSpec - Input';
    prompt = {'Do you want to watch?:', 'FPS'};
    dims = [1 70];
    definput = {'Yes or No', '24'};
    answer = inputdlg(prompt, title, dims, definput);

    % interpet inputs
    WATCH = char(answer(1));
    
    if strcmp(WATCH, 'Yes') || strcmp(WATCH, 'yes')
       WATCH = 1;
    else
       WATCH = 0; 
    end
    
    FPS = str2double(cell2mat(answer(2)));
    
end

function [MaxData] = AreaAnalysis(Region, Ori, Cut)

    [RegRow, RegCol, ~] = size(Region);
    
    % Ask Check For Cut Type
    if Ori == 1 %Hor
        BoxCSize = floor(Cut);
    elseif Ori == 2%Vert
        BoxCSize = floor(Cut);
    end

    % Set Counter and Matrices
    i = 1;
    if Ori == 1
        MaxData = zeros(3,RegRow-BoxCSize-1);
    elseif Ori == 2
        MaxData = zeros(3,RegCol-BoxCSize-1);
    end

    %% Area Analysis
    while true

        % Selects a small box from  Region
        if Ori == 1 %Hor
            Box = Region(i:i+BoxCSize,:,:);
        elseif Ori == 2 %Vert
            Box = Region(:,i:i+BoxCSize,:);
        end

        % Create RGB histogram from Box
        RED = imhist(Box(:,:,1));
        GRE = imhist(Box(:,:,2));
        BLU = imhist(Box(:,:,3));

        % Grab Max Data
        [~ , MaxData(1,i)] = max(RED);
        [~ , MaxData(2,i)] = max(GRE);
        [~ , MaxData(3,i)] = max(BLU);

        % Check when to stop
        if Ori == 1 && i == RegRow-BoxCSize-1 %Hor
            break
        elseif Ori == 2 && i == RegCol-BoxCSize-1  %Vert
            break
        else
            i = i + 1;
        end
                
    end
    
        
end
