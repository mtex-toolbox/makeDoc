function xsl_file = getPublishStyle(type)
% returns the location of the xsl-stylesheet
%
%% Input
% type  - style 
% 
%  * 'latex'
%  * 'html' | 'xml'
%

style =  'publish.xsl';
switch type
  case 'latex'
    style = 'latex.xsl';
  case 'latex2'
    style = 'mxdom2latex.xsl';
  case {'html','xml'}
    style =  'publish.xsl';
end

xsl_file = fullfile(docHelpPath,'resources','style',style);