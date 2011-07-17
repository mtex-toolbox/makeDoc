%% Build the DocHelp Documentation
% this example shows how to publish a documentation

%% Open in Editor

%% Contents

%% Setup of Files
% Generate general toolbox information 

makeToolboxXML

%% 
% location of files for documentation

f = [getFiles(docHelpPath,'*.m') ...
  getFiles(fullfile(docHelpPath,'@DocFile'),'*.m') ...
  getFiles(fullfile(docHelpPath,'tools'),'*.m') ...
  getFiles(fullfile(docHelpPath,'help','docGuide'),'*.m',true)];

%% 
% and treat them as DocFiles

docFiles = DocFile(f);

%% 
% Path to publish output location

docPath = fullfile(docHelpPath,'help');
outputDir = fullfile(docPath,'html');
tmpDir = fullfile(docPath,'tmp');

%% Generate the Function Reference overview pages

makeFunctionsReference(docFiles,'FunctionReference','outputDir',outputDir);

%% Build the Toc for the Toolbox

makeHelpToc(docFiles,'docGuide',...
  'FunctionMainFile','FunctionReference',...
  'outputDir',outputDir);

%% Publish all Files

publish(docFiles,...
  'mainFile','docGuide',...
  'format','html',...
  'outputDir',outputDir,...
  'tempDir',tmpDir,...
  'force',true,...
  'evalCode',true);

%% Build the Examples

%%
% location of the examples

demoPath = fullfile(docHelpPath,'examples');
demoFiles = DocFile(demoPath);

%%
% publishing

publish(demoFiles,...
  'outputDir',fullfile(demoPath,'html'),...
  'tempDir',tmpDir,...
  'force',true,...
  'evalCode',false);

%%
% and demos need a toc file

makeDemoToc(demoFiles,'outputDir',demoPath);

%% Create Help
% Enable search in documentation (also F1 Help in recent matlab)

builddocsearchdb(outputDir);
copyfile(fullfile(outputDir,'helpsearch'),fullfile(docPath,'helpsearch'))

%% 
% Create the help.jar

system(['jar -cf ' fullfile(docPath,'help.jar') ' -C ' outputDir ' .']);
copyfile(fullfile(outputDir,'helptoc.xml'),docPath)


%%
% Clean up

% rmdir( fullfile(docPath,'html') , 's' )
% rmdir( fullfile(docPath,'tmp') , 's' )


