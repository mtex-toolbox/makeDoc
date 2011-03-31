function general = getPublishGeneral(type)
% list of files generally copied to preserve css-style, javascripts, icons in
% html output

%% Input
% type  - style 
% 
%  * 'latex'
%  * 'html' | 'xml'
%

general = getFiles(fullfile(docHelpPath,'resources','general'),'*.gif|*.js|*.css');

