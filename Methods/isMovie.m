function [Output] = isMovie(FileName)
    [~,~,FileType] = fileparts(FileName);
    
    switch FileType
        case '.avi'; Output = 1;
        case '.mj2'; Output = 1;
        case '.mpg'; Output = 1;
        case '.asf'; Output = 1;
        case '.asx'; Output = 1;
        case '.wmv'; Output = 1;
        case '.mp4'; Output = 1;
        case '.m4v'; Output = 1;
        case '.mov'; Output = 1;
        otherwise; Output = 0;
    end
end