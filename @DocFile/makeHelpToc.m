function makeHelpToc(docFiles, mainFile, varargin )
% make a toc for a matlab help
%
% Input
%  docFiles - a list of @DocFile
%  mainFile - the @DocFile of a name of a DocFile where to start, this DocFile should have a *.toc
%
% Options
%  outputDir        -  the folder where to put all function--pages
%  FunctionMainFile -  a name of a DocFile, where the Functions pages begin
%  ProductPage      -  the root of the toc starts with this page
%
% See also
% DocFile/makeFunctionsReference DocFile/makeDemoToc DocFile/publish

[options,mainFile,docFiles] = parseArguments(varargin,docFiles,mainFile);


options.functions_cat = 'funcref_cat';
pos = find(ismember({docFiles.sourceFile},options.FunctionMainFile.sourceFile));
if ~isempty(pos)
  docFiles(pos).sourceInfo.docName = options.functions_cat;
end


[dom,document] = domCreateDocument('toc');
makeToc(dom,document,mainFile,docFiles,options);


xmlwrite(fullfile(options.outputDir,'helptoc.xml'),dom);


function [options,mainFile,docFiles] = parseArguments(options,docFiles,mainFile)

if ~isstruct(options)
  if mod(numel(options),2)
    error('forgotten argument of option');
  end
  options = cell2struct(options(2:2:end)',options(1:2:end)');
end

if ~isfield(options,'outputDir')
  options.outputDir = cd;
end

if ~isfield(options,'FunctionMainFile')
  options.FunctionMainFile = docFiles(1);
end

if ~isa(options.FunctionMainFile,'DocFile')
  options.FunctionMainFile = getFilesByName(docFiles,options.FunctionMainFile);
end

if ~isa(mainFile,'DocFile')
  mainFile = getFilesByName(docFiles,mainFile);
end


if ~isfield(options,'ProductPage')
  [xml,content] = getToolboxXML();
  options.ProductPage = content.productpage;  
  mainFile.sourceInfo.docName = regexprep(options.ProductPage,'\.html','');
end


function makeToc(dom,parentNode,file,docFiles,options,Label)

if nargin < 6, Label = ''; end

node = createTocNode(dom,parentNode,file,Label);

if length(file)>1
  file = file(1);
  dispPerm(['Warning: The file ' file.sourceInfo.name ' appears twice']);
end

if hasTocFile(file)  
  [tocEntries,tocLabel] = readTocFile(file);
  for k = 1:numel(tocEntries)
    tocFile = getFilesByName(docFiles,tocEntries{k});
    if isempty(tocFile)
      disp([tocEntries{k} ' not found']);
    else
      makeToc(dom,node,tocFile,docFiles,options,tocLabel{k});
    end
  end
elseif strfind(file.sourceInfo.name,'_index')
  nam = file.sourceInfo.name(1:end-6);
  
  info = [docFiles.sourceInfo];
  match = ~cellfun('isempty',regexp({info.path}, [nam '$']));
  
  for tocFiles = docFiles(match)
    makeToc(dom,node,tocFiles,docFiles,options);
  end
end


function node = createTocNode(dom,parentNode,docFile,Label)

sourceInfo = docFile.sourceInfo;

if isFunction(docFile)
  node = domAddChild(dom,parentNode,'tocitem', sourceInfo.name,...
    {'target',[sourceInfo.docName '.html']});
else
   
  if ~isempty(Label)
    title = Label;
  else
    title = fgetl(docFile);          
  end
  if isempty(title), title = sourceInfo.docName; end
  
  attributes = {'target',[sourceInfo.docName '.html']};
  
  node = domAddChild(dom,parentNode,'tocitem', strtrim(title), attributes);
  
end
