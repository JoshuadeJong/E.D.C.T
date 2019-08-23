function [Data] = LineSpec(FileName)
% LineSpec takes a video or picture and looks at the light intensity across
% a given line.
%
% Author: Joshua de Jong
% Email: dejongjj@rams.colostate.edu
% Date: 7/5/2018
% Version 1.0

% Patch Notes
%
%

InputAmount = 3;

%% Check for correct toolboxes
    if ToolboxCheck == 0
       return; 
    end

%% Check if user gave inputs
    if nargin ~= InputAmount
       FileName = InputAsk; 
    end

%% If movie
if isMovie(FileName)
    
    % Find Movie
    FullFileName = FindFile(FileName);
    
    % Open Movie
    mov = VideoReader(FullFileName); %Read in Movie
    thisFrame = readFrame(mov); % Grab first Frame
    
    % Check if User wants to Watch
    [WATCH, FPS] = WatchAsk;
    
    if WATCH
        videoPlayer = vision.VideoPlayer('Position', [0 0 800 800]); % Create Video Player
    end
    
    % Ask for Line Coord
    Rec = GetRect(thisFrame);
    
    [xs, ys] = GetPxs(Rec(1), Rec(2), Rec(3), Rec(4));
    
    % Set Constants
    line_color = [255, 255, 0];
    k = min(length(xs), length(ys));
    FrameCount = 1;
    meanNum = 10; % Curve Average Depth
    rds = 7; % Smooth
    
    % Setup Data Storage
    Means = zeros(k,meanNum);
    Data = zeros(5,k,1000);
    
    % Setup figure
    figure(1)
    
    % Watch Movie
    while hasFrame(mov)
        % FPS Timer
        tic
        
        % Calculate Data 
        distrib = GetPxDist(thisFrame, xs, ys);
        [r, g, b] = GetPxDistMulti(thisFrame, xs, ys);
        smth = movingaverage(distrib, rds);
        Data(1,:, FrameCount) = distrib;
        Data(2,:, FrameCount) = smth;
        Data(3,:, FrameCount) = r;
        Data(4,:, FrameCount) = g;
        Data(5,:, FrameCount) = b;

        if FrameCount <= meanNum
            Means(:, FrameCount) = smth(:);
        else
            Means = cat(2, Means(:, 2:meanNum), smth');
        end
        
        %curMean = mean(Means, 2);
        meanV = mean(smth)*ones(1, length(smth));
        
       
        % Step Graph
        if WATCH
            % Light Intensity
            subplot(2,1,1);
            x = 1:length(smth);
            %plot(x, smth, 'r', x, meanV, '--b', x, curMean, '-.g', x, distrib, ':k')
            plot(x, smth, 'r', x, meanV, '--b', x, distrib, ':g')

            
            axis([0, k, 0, 255])
            xlabel('Line Position')
            ylabel('Light Intesity')
            title('Light Intensity')
            %legend('Smoothed Data','Mean Intesity', 'Mean Curve', 'Raw Data')
            legend('Smoothed Data','Mean Intesity', 'Raw Data')

            
            % Color Intensity
            subplot(2,1,2);
            %plot(x, movingaverage(r, rds), 'r', x, movingaverage(g, rds), 'g', x, movingaverage(b,rds), 'b')
            %hold on
            plot(x, r, '.r', x, g, '.g', x, b, '.b')
            %hold off
            
            axis([0, k, 0, 255]);
            xlabel('Line Position')
            ylabel('Color Intesity')
            title('Color Intensity')
        end
        
        % Draw Line into Frame
        for i = 1:k
            thisFrame(ys(i), xs(i), :) = line_color(:);
        end

        % Step Video Player
        if WATCH
            step(videoPlayer, thisFrame);
        end
        
        % FPS Pause
        if WATCH
            pause(1/FPS - toc)
        end

        % Grab Next Frame
        thisFrame = readFrame(mov);
        FrameCount = FrameCount + 1;

    end
    
    Data = Data(:,:, FrameCount - 1);

%% If picture
% elseif isPicture(FileName)
%     % Find Picture
%     FullFileName = FindFile(FileName);
%     
%     % Open Picture
    

%% If nothing
else
    fprintf('LineSpec - Please give a Movie or Picure File\n');
    return
end



end

% GUI and Option Functions
function [FileName] = InputAsk()
    % Ask for inputs
    title = 'LineSpec - Input';
    prompt = {'Enter Video file:'};
    dims = [1 70];
    definput = {'Tornado_Example.mp4'};
    answer = inputdlg(prompt, title, dims, definput);

    % interpet inputs
    FileName = char(answer(1));
end

function [WATCH, FPS] = WatchAsk()
    % Ask for inputs
    title = 'LineSpec - Input';
    prompt = {'Do you want to watch?:', 'FPS'};
    dims = [1 70];
    definput = {'Yes or No', '60'};
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

function [Rec] = GetRect(Image)
% Buttons
h = figure('Visible', 'off', 'Position', [0 0 600 600]);
movegui(h,'center');
axes('Units', 'pixels');
imshow(Image);

% Title Text
uicontrol('Style', 'text',...
    'String', 'Draw a line',...
    'Position', [200 550 200 20]);

% Done Button
btn = uicontrol('Style', 'togglebutton',...
    'String', 'Done',...
    'Position', [430 50 60 25]);

% Cancel Button
btn2 = uicontrol('Style', 'togglebutton',...
    'String', 'Cancel',...
    'Position', [500 50 60 25]);

% Redraw Button
btn3 = uicontrol('Style', 'togglebutton',...
    'String', 'Redraw',...
    'Position', [100 50 60 25]);

% Make Ui visible
h.Visible = 'on';


% Logic
Rec = getPosition(imline);
if Rec(1,1) > Rec(2,1)
    Rec = [Rec(1,:), Rec(2,:)];
else
    Rec = [Rec(2,:), Rec(1,:)];
end

RegionPic = insertShape(Image, 'Line', Rec, 'Linewidth', 2, 'Color', 'green');
imshow(RegionPic)
drawnow

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
        
        btn3.Value = 0;
    end
    
    pause(.0001)
    
    if btn2.Value
        
        [RowS, ColumnS] = size(Image);
        Rec = [floor(RowS/2) 1; floor(RowS/2) ColumnS];
        
        break
    end
    
end

close(h)

end

% Data Functions
function[xs_out, ys_out] = GetPxs(x_1, y_1, x_2, y_2)
if x_1 > x_2
    x2 = ceil(x_1);
    y2 = y_1;
    x1 = floor(x_2);
    y1 = y_2;
else
    x1 = ceil(x_1);
    y1 = y_1;
    x2 = floor(x_2);
    y2 = y_2;
end
dx = x2-x1;
dy = y2-y1;
n = max(int16(abs(dx)), int16(abs(dy)));
xs = zeros(1, n);
ys = zeros(1, n);
if int16(x1) == int16(x2)
    %vertical
    xs(:) = int16(x1);
    ys = int16(linspace(min(y1, y2), max(y1, y2), n));
elseif abs(dy) > dx
    % majority vertical
    slope = dx/dy;
    for i = 1:n
        xs(i) = x1 + slope * i;
    end
    ys = int16(linspace(min(y1, y2), max(y1, y2), n));
else
    % majority horizontal, or horizontal
    slope = dy/dx;
    for i = 1:n
        ys(i) = y1 + slope * i;
    end
    xs = int16(linspace(min(x1, x2), max(x1, x2), n));
end
xs_out = int16(xs);
ys_out = int16(ys);
end

function [movavg_x] = movingaverage(x, radius)

    if nargin == 1
        radius = 4;
    end
    
    [n1, n2] = size(x);
    n = max(n1, n2);
    xout = zeros(1, n);
    
    for i=1:n
        low = max(1, i - radius);
        high = min(n, i + radius);
        xout(i) = mean(x(low:high));
    end
    
    movavg_x = xout;
end

function[distrib] = GetPxDist(image_full, xs, ys)

    n = uint16(min(length(xs), length(ys)));
    d = zeros(1, n);

    for i = 1:n
        d(i) = 0.2857*double(image_full(ys(i), xs(i), 1))+ 0.5714*double(image_full(ys(i), xs(i), 2)) + 0.14285*double(image_full(ys(i), xs(i), 3));
    end

    distrib = d;

end

function[ro, go, bo] = GetPxDistMulti(image_full, xs, ys)

    n = uint16(min(length(xs), length(ys)));
    r = zeros(1, n);
    g = zeros(1, n);
    b = zeros(1, n);
    
    for i = 1:n
        r(i) = double(image_full(ys(i), xs(i), 1));
        g(i) = double(image_full(ys(i), xs(i), 2));
        b(i) = double(image_full(ys(i), xs(i), 3));
    end
    
    ro = r;
    go = g;
    bo = b;
    
end