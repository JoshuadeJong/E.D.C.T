function [fullFileName] = FindFile(FileName)

    baseFileName = FileName;
    folder = fileparts(which(baseFileName)); % Determine where the folder is
    fullFileName = fullfile(folder, baseFileName);

    if ~exist(fullFileName, 'file')
        % It doesn't exist in the current folder.
        % look on the search path.
        if ~exist(baseFileName, 'file')
            % If doesn't exist on the search path either.
            % Alert user that file can't be found
            title = 'File Error';
            warningMessage = sprintf('Error: the input file\n%s\n was not found. Click OK to exit.', fullFileName);
            uiwait(warndlg(warningMessage, title));
            return;
        end
        fullFileName = baseFileName;
    end
end