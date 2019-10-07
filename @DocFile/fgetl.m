function str = fgetl(file,varargin)

file = file.sourceFile;
  
fid = fopen(file,'r');
if fid < 0
  str = '';
else
  str = fgetl(fid,varargin{:});
  fclose(fid);
  
  str = regexprep(str,'\r','');
  str = strtrim(regexprep(str,'%%',''));
end
