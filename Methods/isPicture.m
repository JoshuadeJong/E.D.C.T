function [Output] = isPicture(FileName)
    [~,~,FileType] = fileparts(FileName);
    
    switch FileType
        case '.bmp'; Output = 1;
        case '.gif'; Output = 1;
        case '.hdf'; Output = 1;
        case '.jpeg'; Output = 1;
        case '.jpg'; Output = 1;
        case '.jp2'; Output = 1;
        case '.jpf'; Output = 1;
        case '.jpx'; Output = 1;
        case '.j2c'; Output = 1;
        case '.j2k'; Output = 1;
        case '.pbm'; Output = 1;
        case '.pcx'; Output = 1;
        case '.pgm'; Output = 1;
        case '.png'; Output = 1;
        case '.pnm'; Output = 1;
        case '.ppm'; Output = 1;
        case '.ras'; Output = 1;
        case '.tiff'; Output = 1;
        case '.tif'; Output = 1;
        case '.xwd'; Output = 1;
        case '.cur'; Output = 1;
        case '.ico'; Output = 1;
        otherwise; Output = 0;
    end
end
