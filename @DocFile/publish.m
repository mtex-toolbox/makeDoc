function [html_out,success] = publish( docFiles, options)
% publishes the docFiles
%
% Syntax
%   publish(docFiles, options)
%
% Input
%  docFiles - a list of @DocFiles
%  options.outDir  -
%  options.tmpDir  -
%  options.force      -
%  options.publishSettings - struct like <matlab:doc('publish') publish>
%  options.xmlDom
%  options.LaTex   - 'Matlab', 'mathJax'
%
% See also
% DocFile/makeHelpToc makeToolboxXML

if isempty(dir(options.tmpDir)), mkdir(options.tmpDir); end
if isempty(dir(options.outDir)), mkdir(options.outDir); end
options = setDefault(options,'imageDir',options.outDir);
options = setDefault(options,'force',false);

%% prepare files to publish
for k = 1:length(docFiles)
  
  target = fullfile(options.tmpDir,docFiles(k).targetTemporary);
    
  if fileIsNewer(docFiles(k).sourceFile,target) || options.force
    
    disptmp(sprintf('preparing %s\n',docFiles(k).sourceInfo.docName));
          
    try
      if isFunction(docFiles(k)) || isClass(docFiles(k))
        text = generateScript(docFiles(k),options);
      else
        text = read(docFiles(k).sourceFile);
        
        % extract author
        [startIndex,endIndex] = regexp(text,'% Author: .*?\n');
        docFiles(k).sourceInfo.author = text(startIndex+10:endIndex);
        text(startIndex:endIndex) = [];
        
        % globaly replace formulae, tables, etc.
        text = globalReplacements(text,options);
      end
      
    catch %#ok<CTCH>
      %disptmp(newline);
      dispPerm(['  Error preparing <a href="matlab: edit(''' ...
        docFiles(k).sourceFile ''')">',docFiles(k).sourceInfo.docName '</a>']);
      lasterr
      disp(' ');
      continue
    end
    
    fid = fopen(target,'w');
    if fid > 0
      fwrite(fid,text);
      fclose(fid);
    end
    
    disptmp('');
  end
end

% finished script generation
dispPerm(' ');

copy(DocFile(getPublishGeneral),options.outDir);


%% publish files

% set up publish settings
pubSettings = options.publishSettings;
pubSettings = setDefault(pubSettings,'format','html');
pubSettings = setDefault(pubSettings,'figureSnapMethod','print');
pubSettings = setDefault(pubSettings,'useNewFigure',true);
pubSettings = setDefault(pubSettings,'evalCode',true);
pubSettings = setDefault(pubSettings,'imageFormat','png');
pubSettings = setDefault(pubSettings,'stylesheet',getPublishStyle('html'));
pubSettings.catchError = false;
pubSettings.outputDir = options.outDir;

% change directory
oldDir = cd; cd(options.tmpDir);

% remember settings
settings = getappdata(0,'mtex');

for docFile = docFiles
  
  % reapply settings
  setappdata(0,'mtex',settings);
  
  % final html name with script_xxx_xxx
  htmlTarget = fullfile(options.outDir,[docFile.sourceInfo.docName '.html']);

  % nothing to do
  if ~fileIsNewer(docFile.sourceFile,htmlTarget) && ~options.force, continue; end
    
  disptmp([ 'publishing: ' docFile.sourceInfo.docName])
  
  % update xml file
  stylePath = fileparts(pubSettings.stylesheet);
  
  try
          
    evalin('base','clear variables'); close all;

    % update xml file
    if isfield(options,'xml')      
      str = strrep(docFile.sourceFile,mtex_path,'');
      options.xml.toolbox.pageSource.Text = strrep(str,'../examples/','');
      options.xml.toolbox.htmlTarget = [docFile.sourceInfo.docName '.html'];
      if isfield(docFile.sourceInfo,'author')
        options.xml.toolbox.author.Text = docFile.sourceInfo.author;
      end
      struct2xml(options.xml,fullfile(stylePath,'toolbox.xml'));      
    end
    
    html_out = publish(docFile.targetTemporary, pubSettings);
            
    movefile(html_out,htmlTarget);
      
    [~,targetName] = fileparts(html_out);
    
    if 1
      % crop all images
      pngTarget = fullfile(options.outDir,[targetName '*.png']);
      if ~isempty(dir(pngTarget))
        unix(['mogrify -trim ' pngTarget]);
      end
    
      % move image files to new directory
      attache = dir(fullfile(options.outDir,[targetName '*.*']));
      for n=1:numel(attache)
        newName = regexprep(attache(n).name,targetName,docFile.sourceInfo.docName);
        movefile(fullfile(options.outDir,attache(n).name),fullfile(options.imageDir,newName),'f');
      end
    end    
    
  catch e
    
    success = false;
    
    % remove 
    delete([options.outDir filesep 'script_*']) 
    %disptmp('');
    dispPerm(['  Error publishing <a href="matlab: edit(''' ...
      docFile.sourceFile ''')">',docFile.sourceInfo.docName '</a>']);
            
    f = find(strncmp(docFile.targetTemporary,{e.stack.name},length(docFile.targetTemporary)-2));
    if ~isempty(f)
      stack = e.stack(f);
      dispPerm(['   (in file <a href="matlab: opentoline(''' ...
        docFile.sourceFile ''',' num2str(stack.line(1)) ',0)">' docFile.sourceInfo.name '</a>)']);
      fprintf('   %s\n' ,regexprep(e.message,'[\n\r]',''));
    end
    
  end
  
end

if isfield(options,'xmlDom'), mytoolbox.removeChild(node); end
cd(oldDir);

end

function opt = setDefault(opt,field,value)

if ~isfield(opt,field), opt.(field) = value; end

end