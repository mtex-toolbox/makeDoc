function copy(docFile,destination)
% copy all docFiles to the given destination folder 

[~,~,ext] = fileparts(destination);

if isempty(dir(destination)) && isempty(ext)
  mkdir(destination);
end

for k=1:numel(docFile)
  copyfile(docFile(k).sourceFile,destination);
end
