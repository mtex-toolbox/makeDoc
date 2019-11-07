function makeHelpToc(docFiles, mainFile, outFile )
% make a toc for a matlab help
%
% Syntax
%
%   makeHelpToc(docFiles,mainFile,'helptoc.xml')
%
% Input
%  docFiles - a list of @DocFile
%  mainFile - the @DocFile of a name of a DocFile where to start, this DocFile should have a *.toc
%
% See also
% DocFile/publish

% turn mainFile into a docFile
if ~isa(mainFile,'DocFile'), mainFile = getFilesByName(docFiles,mainFile); end

% make dom
[dom,document] = domCreateDocument('toc');
makeToc(dom,document,mainFile,docFiles);

% write to file
xmlwrite(outFile,dom);

end


function makeToc(dom,parentNode,file,docFiles,Label)
% recursevly walk through directories with a toc file

if nargin < 5, Label = ''; end

node = createTocNode(dom,parentNode,file,Label);

if length(file)>1
  
  dispPerm(['Warning: The file ' file(1).sourceInfo.name ' appears twice']);
  file
  file = file(1);
end

if hasTocFile(file)  
  [tocEntries,tocLabel] = readTocFile(file);
  for k = 1:numel(tocEntries)
    tocFile = getFilesByName(docFiles,tocEntries{k});
    if isempty(tocFile)
      disp([tocEntries{k} ' not found']);
    else
      makeToc(dom,node,tocFile,docFiles,tocLabel{k});
    end
  end
elseif strfind(file.sourceInfo.name,'_index')
  nam = file.sourceInfo.name(1:end-6);
  
  info = [docFiles.sourceInfo];
  match = ~cellfun('isempty',regexp({info.path}, [nam '$']));
  
  for tocFiles = docFiles(match)
    if strcmp(tocFiles.sourceInfo.name, nam)
      makeToc(dom,node,tocFiles,docFiles);
    end
  end
  for tocFiles = docFiles(match)
    if ~strcmp(tocFiles.sourceInfo.name, nam)
      makeToc(dom,node,tocFiles,docFiles);
    end
  end
end
end

function node = createTocNode(dom,parentNode,docFile,Label)
% create node

sourceInfo = docFile.sourceInfo;

if isFunction(docFile) || isClass(docFile)
  node = domAddChild(dom,parentNode,'tocitem', sourceInfo.name,...
    {'target',[sourceInfo.docName '.html']});
else
   
  %docFile
  if ~isempty(Label)
    title = Label;
  else
    title = fgetl(docFile);          
  end
  if isempty(title), title = sourceInfo.docName; end
  
  attributes = {'target',[sourceInfo.docName '.html']};
  
  node = domAddChild(dom,parentNode,'tocitem', strtrim(title), attributes);
  
end
end