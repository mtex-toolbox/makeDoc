function docFile = exclude(docFile,varargin)
% remove directories or files from docfile

for i = 1:nargin-1
  
  docFile = docFile(cellfun('isempty',strfind({docFile.sourceFile},varargin{i})));
  
end
