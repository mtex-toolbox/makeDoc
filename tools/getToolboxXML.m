function [file,content] = getToolboxXML()
% read the toolbox xml file
%
%% Output
% file    - location of the xml--file
% content - struct with the xml--nodes as fields
%
%% See also
% makeToolboxXML


file = fullfile(docHelpPath,'resources','style','toolbox.xml');

if nargout > 1
  dom = xmlread(file);
  
  content.name = node2char(dom,'name');
  content.fullname = node2char(dom,'fullname');
  content.versionname = node2char(dom,'versionname');
  content.productpage = node2char(dom,'procuctpage');
  content.icon = node2char(dom,'icon'); 
  
end


function str = node2char(dom,name)

list = dom.getElementsByTagName(name);
firstNode = list.item(0);
str = char(firstNode.getTextContent);
