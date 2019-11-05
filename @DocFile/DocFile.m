function file = DocFile(files,varargin)
% constructor 
%
% Syntax
% files = DocFile(path) - recusively adds all files in sub--dirs
% files = DocFile({fname,fname,...}) - adds a given cell--array of full--fill names 
% files = DocFile('function') - add a single function which is on search path
%
% See also
% getFiles
%
% Example
%   doc = DocFile(fullfile(docHelpPath,'help','docGuide'))
%

if nargin < 1
  error('I need at least one file or path!')
end

if ~iscell(files) && isfolder(files)
  files = getFiles(files,'*.m',true);
end

file = struct(...
  'sourceFile',reshape(files,1,[]),...
  'sourceInfo',struct(...
  'docName','',...
  'isFunction',false,...
  'Syntax','',...
  'name','',...
  'ext','',...
  'path',''),...
  'targetTemporary','');

for k=1:numel(file)
  currentFile = file(k);
  sourceInfo = currentFile.sourceInfo;
  %   if ~isempty(dir(currentFile.sourceFile))
  [sourceInfo.path,sourceInfo.name,sourceInfo.ext] = fileparts(currentFile.sourceFile);
  if isempty(sourceInfo.path)
    currentFile.sourceFile = which(currentFile.sourceFile);
    [sourceInfo.path,sourceInfo.name,sourceInfo.ext] = fileparts(currentFile.sourceFile);
  end
  
  switch sourceInfo.ext
    case '.m'
      [currentFile, sourceInfo] = setupmfileInfo(currentFile,sourceInfo);
    otherwise      
%       target = fullfile(outputDir,sourceInfo.name);
      currentFile.targetTemporary = [sourceInfo.name,sourceInfo.ext];
  end
  currentFile.sourceInfo = sourceInfo;
%   currentFile.outputDir = outputDir;
  file(k) = currentFile;
  %   end
end

file = class(file,'DocFile');



function [currentFile, sourceInfo] = setupmfileInfo(currentFile, sourceInfo)

pos = strfind(sourceInfo.path,'@');
if ~isempty(pos)
  sourceInfo.docName = [sourceInfo.path(pos+1:end) '.' sourceInfo.name];
else
  sourceInfo.docName = sourceInfo.name;
end
% 
% target = fullfile(outputDir,sourceInfo.docName);
currentFile.targetTemporary = ['script_' regexprep(sourceInfo.docName,'\.','__'),sourceInfo.ext];
% currentFile.targetFile = [target,'.html'];
% 
% % eval or not?
% [sourceInfo.isFunction,sourceInfo.Syntax] = isFunction(currentFile.sourceFile);
% if sourceInfo.isFunction
%   currentFile.targetTemporary(end+1:end+3) = 'ref';
% end
% 

