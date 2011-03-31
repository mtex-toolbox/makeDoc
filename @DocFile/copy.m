function copy(docFile,destination)
% copy all docFiles to the given destination folder 

if isempty(dir(destination))
  mkdir(destination);
end

for k=1:numel(docFile)
  copyfile(docFile(k).sourceFile,destination);
end