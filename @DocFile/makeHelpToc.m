function [ output_args ] = makeHelpToc(docFiles, mainFile, varargin )
% make a toc for a matlab help

%% Input
% docFiles - a list of @DocFile
% mainFile - the @DocFile of a name of a DocFile where to start, this DocFile should have a *.toc
%
%% Options
% outputDir        -  the folder where to put all function--pages
% FunctionMainFile -  a name of a DocFile, where the Functions pages begin
% ProductPage      -  the root of the toc starts with this page
%
%% See also
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


function makeToc(dom,parentNode,file,docFiles,options,icon)

if nargin < 6, icon = ''; end


node = createTocNode(dom,parentNode,file,options,icon);

if hasTocFile(file)  
  [tocEntries,tocIcons] = readTocFile(file);
  for k = 1:numel(tocEntries)
    tocFile = getFilesByName(docFiles,tocEntries{k});
    if ~isempty(tocFile)
      makeToc(dom,node,getFilesByName(docFiles,tocEntries{k}),docFiles,options,tocIcons{k});
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


function node = createTocNode(dom,parentNode,docFile,options,icon)

sourceInfo = docFile.sourceInfo;


if isFunction(docFile)
  node = domAddChild(dom,parentNode,'tocitem', sourceInfo.name,...
    {'target',[sourceInfo.docName '.html'],...
    'image','$toolbox/matlab/icons/help_fx.png'});
else
  str = read(docFile);
  
  titles = regexp(str,'(?<=^%%|\n%%)(.*?)(?=(\n|$))','match');
  titles = regexprep(titles,'\[\[(.*?),(.*?)\]\]','$2'); 
  
  if isempty(titles), titles = {sourceInfo.docName}; end
  
  attributes = {'target',[sourceInfo.docName '.html']};
  if nargin > 3 &&  ~isempty(icon) 
    attributes = [attributes,'image',['$toolbox/matlab/icons/' icon '.gif']];
  end
  
  node = domAddChild(dom,parentNode,'tocitem', strtrim(titles{1}), attributes);
    
  for k=2:numel(titles)
    title = strtrim(titles{k});
    if ~isempty(title) && ~strncmp(title,'%',1) && ~badKeyword(title)
    domAddChild(dom,node,'tocitem', title,...
      {'target',[sourceInfo.docName '.html#' num2str(k-1)]});
    end
  end
end







% function m2struct(toc,parent,mfile,icon)