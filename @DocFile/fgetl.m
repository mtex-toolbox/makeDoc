function str = fgetl(file,varargin)

fid = fopen(file.sourceFile,'r');
if fid < 0
  str = '';
else
  str = fgetl(fid,varargin{:});
  fclose(fid);
  
  str = regexprep(str,'\r','');
  str = strtrim(regexprep(str,'%%',''));
end
