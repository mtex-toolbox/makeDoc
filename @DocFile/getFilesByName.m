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
if ischar(names), names = {names}; end
docNames = cellfun(@(x) x.docName, {docFiles.sourceInfo},'UniformOutput',false);
for k = 1:numel(names)
  exact = strcmp(docNames,names{k});
  if any(exact)
    docFileNames(strcmp(docFileNames,names{k}) | exact) = {''};
    docFileNames(exact) = names(k);
  end
end


[inName, order] = ismember(docFileNames,names);
tocFiles = [];
if any(inName)
  docFiles = docFiles(inName);
  [order, ndx] = sort(order(inName));
  tocFiles = docFiles(ndx);
end
