function content = save( file, content )

% if isa(file,'DocFile')
%   file = file.sourceFile;
% end
  
fid = fopen(file,'w');
fwrite(fid,content);
fclose(fid);
