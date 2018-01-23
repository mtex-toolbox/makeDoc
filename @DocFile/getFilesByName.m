function [ tocFiles,inName ] = getFilesByName( docFiles, names )
% find a specific docFile by calling its name
%
% Input
%  docFiles  - @docFiles
%  names     - string or cell--array of strings
%
% Output
%  tocFiles  - the specific docFiles in order of |names|
%  inName    - logical vector, true if |name| is in docFiles list
%

docFileNames = cellfun(@(x) x.name, {docFiles.sourceInfo},'UniformOutput',false);

[inName, order] = ismember(docFileNames,names);
tocFiles = [];
if any(inName)
  docFiles = docFiles(inName);
  [order, ndx] = sort(order(inName));  
  tocFiles = docFiles(ndx);
end
