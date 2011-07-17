function s = source(file)
% display the source of the DocFile

if nargout > 0
  s = file.sourceFile;
else
  edit(file.sourceFile);
end