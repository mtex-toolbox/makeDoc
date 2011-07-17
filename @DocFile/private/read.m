function content = read( file )

if isa(file,'DocFile')
  file = file.sourceFile;
end
  
fid = fopen(file,'r');
if fid < 0
  content = '';
else
  content = fread(fid,'*char')';
  fclose(fid);
  
  content = regexprep(content,'\r','');
end


