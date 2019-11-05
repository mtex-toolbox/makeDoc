function helpStr = getFormatedDoc(file, options)
% returns a processed string for normal script files
%
% Input
%  file     - current file
%
% Output
%  helpString - a string for publishing
%
% See also
% DocFile/getFormatedRef DocFile/publish

helpStr = read(file);
helpStr = globalReplacements(helpStr,options);
