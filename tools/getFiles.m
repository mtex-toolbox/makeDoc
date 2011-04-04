function files = getFiles(root, pattern, recursive)
% collects all files at a given location
%
%% Syntax
% files = getFiles(root) - returns a cell--array of files at location |root|
% files = getFiles(root,pattern) - all files at |root| that matches the pattern.
%    the pattern is regular expression like, e.g
%    '*.m|*.html' to collect all m--files and html--files
% files = getFiles(root,pattern, recursive) - the flag |recursive| is logical,
%    i.e. if |true|, recursively apply pattern to all
%    sub--dirs, otherwise |false| (by default).
%
%% Input
% root      - path (e.g. cd)
% pattern   - a qualifier, by default '*.m' 
% recursive - logical true/false 
%
%% Output
% files     - cell--array of fullpath--files
%
%% See also
% DocFile/DocFile
%
%% Example
%    getFiles(fullfile(cd,'..','..'))
%

if nargin < 2 
  pattern = [];
end

if nargin < 3
  recursive = false;
end

if ~isstruct(pattern)
  if ischar(pattern) && any(strcmp(pattern,{'*.*','*'}))
    pattern = [];
  end
  
  if ~isnumeric(pattern)
    pattern = regexprep(pattern,'(\.)','\\.');
    pattern = regexprep(pattern,'*','(.*)');
    pattern = strcat( '(^', pattern, '$)');
  end
  pattern = struct('pattern',pattern);
end


folder = dir(root)';
isDir = [folder.isdir];
sep = filesep;

files = {};
for file = folder(isDir)
  if recursive && ~strncmp(file.name,'.',1) && ~strcmp(file.name,'private')
    subFolder = [root sep file.name];
    files = cat(2,files, getFiles(subFolder,pattern,recursive));
  end
end

testFiles = {folder(~isDir).name};
if ~isempty(pattern.pattern)
  patternOccurs = false(size(testFiles));
  for test = pattern
    match = regexp(testFiles,test.pattern);
    patternOccurs = patternOccurs | ~cellfun('isempty',match);
  end
else
  patternOccurs = true(size(testFiles));
end

if any(patternOccurs)
  testFiles = testFiles(patternOccurs);
  newfiles = cell(size(testFiles));
  for k=1:numel(testFiles)
     newfiles{k} = [root,sep,testFiles{k}];
  end  
  files = [files newfiles];
end
