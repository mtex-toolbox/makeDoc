function DocHelpInstall
% installs the DocHelp toolbox by adding to the search path
%
%% See also
% DocHelpUninstall

folder = fileparts(mfilename('fullpath'));
addpath(folder);
addpath(fullfile(folder,'examples'));
addpath(fullfile(folder,'tools'));
savepath
rehash;

disp('DocHelp toolbox installed');