function helpStr = getFormatedDoc(file, varargin)
% returns a processed string for normal script files
%
% Input
%  file     - current file
%  docFiles - array of @DocFile for lookup crossref--table
%
% Output
%  helpString - a string for publishing
%
% See also
% DocFile/getFormatedRef DocFile/publish

helpStr = read(file);
helpStr = globalReplacements(helpStr);
