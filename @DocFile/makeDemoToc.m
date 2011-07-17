function [ output_args ] = makeHelpToc(docFiles, varargin )
% create a demo toc for a matlab demo pages

%% Input
% docFiles - a list of @DocFile
%
%% Options
% outputDir        -  the folder where to put all function--pages
%
%% See also
% DocFile/makeFunctionsReference DocFile/publish

[options] = parseArguments(varargin);


[dom,document] = domCreateDocument('demos');
[toolbox,content] = getToolboxXML;

domAddChild(dom,document,'name',content.name);
domAddChild(dom,document,'icon',content.icon);
domAddChild(dom,document,'description',[],{'isCdata','no'});

for docFile = docFiles
  addDemoItem(dom,document,docFile)
end

xmlwrite(fullfile(options.outputDir,'demos.xml'),dom);


function options = parseArguments(options)

if ~isstruct(options)
  if mod(numel(options),2)
    error('forgotten argument of option');
  end
  options = cell2struct(options(2:2:end)',options(1:2:end)');
end

function addDemoItem(dom,paretNode,file)

str = read(file);

titles = regexp(str,'(?<=^%%|\n%%)(.*?)(?=(\n|$))','match');
if isempty(titles), titles = {sourceInfo.docName}; end


demoitem = domAddChild(dom,paretNode,'demoitem');

domAddChild(dom,demoitem,'label',titles{1});
domAddChild(dom,demoitem,'type','M-file');
domAddChild(dom,demoitem,'source',file.sourceInfo.name);




