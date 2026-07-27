function docFile = select(docFile,varargin)
% keep only those directories or files that match one of the patterns
%
% The counterpart of <DocFile.exclude.html exclude>. Each pattern is matched
% as a substring of the full source path, so a page name, a folder or a full
% path all work.
%
% Syntax
%   docFile = select(docFile,'EBSDTutorial')
%   docFile = select(docFile,'Plotting','@EBSD')

if nargin == 1, return; end

sourceFiles = {docFile.sourceFile};
keep = false(size(sourceFiles));

for i = 1:nargin-1

  keep = keep | ~cellfun('isempty',strfind(sourceFiles,varargin{i}));

end

docFile = docFile(keep);
