function makeToolboxXML(varargin)
% generate information about the toolbox to publish
%
%% Input
% 
%% Options
% name -  short name of the toolbox
% fullname - displayed in the header of published html files
% versionname - displayed in the footer of published html files
% productpage - html--file where the whole documentation should start from
% icon  - for toc/demo toc
%
%% See also
% getToolboxXML DocFile/publish

options = parseArguments(varargin);

dom = com.mathworks.xml.XMLUtils.createDocument('mytoolbox');
mytoolbox = dom.getDocumentElement;

node = dom.createElement('name');
node.setTextContent(options.name);
mytoolbox.appendChild(node);

node = dom.createElement('fullname');
node.setTextContent(options.fullname);
mytoolbox.appendChild(node);

node = dom.createElement('versionname');
node.setTextContent(options.versionname);
mytoolbox.appendChild(node);

node = dom.createElement('procuctpage');
node.setTextContent(options.procuctpage);
mytoolbox.appendChild(node);

node = dom.createElement('icon');
node.setTextContent(options.icon);
mytoolbox.appendChild(node);

path = fileparts(mfilename('fullpath'));
xmlwrite(fullfile(path,'..','resources','style','toolbox.xml'),dom);


function options = parseArguments(options)


if ~isstruct(options)
  if mod(numel(options),2)
    error('forgotten argument of option');
  end
  options = cell2struct(options(2:2:end)',options(1:2:end)');
end


if ~isfield(options,'name')
  options.name = 'DocHelp';
end

if ~isfield(options,'fullname')
  options.fullname = '<b>DocHelp</b> a Matlab Toolbox for building Documentation';
end

if ~isfield(options,'versionname')
  options.versionname = 'DocHelp 0.1';
end

if ~isfield(options,'procuctpage')
  options.procuctpage = 'docGuide.html';
end

if ~isfield(options,'icon')
  options.icon = '$toolbox/matlab/icons/book_mat.gif';
end

