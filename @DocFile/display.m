function display( files )
% just display the DocFile object 


fprintf('\n%s = DocFiles ( %d files )\n', inputname(1), numel(files));

if numel(files) < 1
  fprintf('\tEmpty Set\n\n')
  return
end

source = {files.sourceFile};
[root,source] = relativeRoot(source);

if numel(files) > 20
  
  info = [files.sourceInfo];
  ext = strcat( '*' ,unique({info.ext}));
  fprintf('\t(')
  fprintf(' %s |', ext{:});
  fprintf('\b)\n')
  
  sep = regexptranslate('escape',filesep);
  source = regexprep(source, [sep '.*'],[sep '..']);
  source = unique(source);
  [a,ind] = sort(lower(source));
  source = source(ind);
  
end

fprintf('\n\t%s\n',root);
fprintf('\t\t|-%s\n', source{:});
fprintf('\n');



function [root,source] = relativeRoot(absoluteFilePathes)

[root,pos] = relativePos(absoluteFilePathes);
source = cellfun(@(x) x(pos+1:end),absoluteFilePathes,'UniformOutput',false);


function [root,pos] = relativePos(absoluteFilePathes)

rootPattern = absoluteFilePathes{1};
stop = min(cellfun('prodofsize',absoluteFilePathes));

k = 0;
match = true;
while match && k < stop
  k = k+1;
  c = rootPattern(k);
  for l=1:numel(absoluteFilePathes)    
    if c ~= absoluteFilePathes{l}(k)
      match = false;
    end
  end
  
end

pos = regexp(rootPattern,regexptranslate('escape',filesep));
pos = pos(pos<=k);
pos = pos(end);

root = rootPattern(1:pos);





