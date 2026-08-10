function file = DocFile(files,varargin)
% constructor 
%
% Syntax
%   files = DocFile(path) - recursively adds all files in sub--dirs
%   files = DocFile({fname,fname,...}) - adds a given cell--array of full--fill names 
%   files = DocFile('function') - add a single function which is on search path
%
% See also
% getFiles
%
% Example
%   doc = DocFile(fullfile(docHelpPath,'help','docGuide'))
%

if nargin < 1, error('I need at least one file or path!'); end

if ~iscell(files) && isfolder(files)
  files = getFiles(files,'*.m',true);
end

% every field a DocFile may ever carry has to be declared here, including
% 'author', which is only filled in later by publish: the sourceInfo structs
% of a file list are concatenated ([files.sourceInfo] in needsPublish,
% display, makeHelpToc) and MATLAB refuses that as soon as one element has a
% field the others lack
file = struct(...
  'sourceFile',reshape(files,1,[]),...
  'sourceInfo',struct(...
  'docName','',...
  'isFunction',false,...
  'Syntax','',...
  'name','',...
  'ext','',...
  'path','',...
  'author',''),...
  'targetTemporary','');

for k=1:numel(file)
  currentFile = file(k);
  sourceInfo = currentFile.sourceInfo;
  
  [sourceInfo.path,sourceInfo.name,sourceInfo.ext] = fileparts(currentFile.sourceFile);
  if isempty(sourceInfo.path)
    currentFile.sourceFile = which(currentFile.sourceFile);
    [sourceInfo.path,sourceInfo.name,sourceInfo.ext] = fileparts(currentFile.sourceFile);
  end
  
  switch sourceInfo.ext
    case '.m'
      [currentFile, sourceInfo] = setupmfileInfo(currentFile,sourceInfo);
    otherwise      
      currentFile.targetTemporary = [sourceInfo.name,sourceInfo.ext];
  end
  currentFile.sourceInfo = sourceInfo;

  file(k) = currentFile;
end

file = class(file,'DocFile');

function [currentFile, sourceInfo] = setupmfileInfo(currentFile, sourceInfo)

pos = strfind(sourceInfo.path,'@');
if ~isempty(pos)
  sourceInfo.docName = [sourceInfo.path(pos+1:end) '.' sourceInfo.name];
else
  sourceInfo.docName = sourceInfo.name;
end

% we need to replace '.' by '__' since MATLAB is not able to publish files
% with a '.' in it
currentFile.targetTemporary = ['script_' regexprep(sourceInfo.docName,'\.','__'),sourceInfo.ext];


