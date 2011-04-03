function DocHelpUninstall
% uninstalls the DocHelp toolbox by removing from the search path
%
%% See also
% DocHelpInstall

folder = fileparts(mfilename('fullpath'));
rmpath(folder);
rmpath(fullfile(folder,'examples'));
rmpath(fullfile(folder,'tools'));
savepath

disp('DocHelp toolbox uninstalled');