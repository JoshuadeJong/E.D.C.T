function [Continue] = ToolboxCheck()
%% Check user has correct toolboxes installed

%Check for required toolboxes
NumToolboxs = 2;
hasIPT = license('test', 'image_toolbox');
hasCV = license('test', 'video_and_image_blockset');

    %Check if all toolboexes
    hasALL = ((hasIPT + hasCV) == NumToolboxs);

    if ~hasALL
        % User does not have the toolbox installed

        % Build message of all missing toolboxs
        message = 'The following Toolbox(s) are missing;';
        message = [message newline];

        if ~hasIPT
            message = [message newline 'Image Processing Toolbox'];
        end
        if ~hasCV
            message = [message newline 'Computer Vision System Toolbox'];
        end

        message = [message newline newline 'Do you want to try to continue anyway?'];

        % Build window properties
        title = 'Toolbox Error';

        % Ask user if they want to continue
        reply = questdlg(message, title, 'Yes', 'No', 'Yes');
        if strcmpi(reply, 'No')
            % User answered No
            fprintf(1, 'Finished running\n');
            Continue = 0;
        else
            Continue = 1;
        end
    else
       Continue = 1; 
    end
end