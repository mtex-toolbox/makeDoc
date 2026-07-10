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
%  options.logFile - path to a persistent log file recording which file is
%                     being processed and any errors (default:
%                     <outDir>/publish_log.txt). Written to disk
%                     immediately so the log survives a MATLAB crash.
%
% See also
% DocFile/makeHelpToc makeToolboxXML

if isempty(dir(options.tmpDir)), mkdir(options.tmpDir); end
if isempty(dir(options.outDir)), mkdir(options.outDir); end
options = setDefault(options,'imageDir',options.outDir);
options = setDefault(options,'force',false);
options = setDefault(options,'logFile',fullfile(options.outDir,'publish_log.txt'));

logFile = options.logFile;
nErrors = 0;
writeLog(logFile,sprintf('==== publish run started: %d file(s) ====',numel(docFiles)));

%% prepare files to publish
for k = 1:length(docFiles)
  
  target = fullfile(options.tmpDir,docFiles(k).targetTemporary);
    
  if fileIsNewer(docFiles(k).sourceFile,target) || options.force
    
    disptmp(sprintf('preparing %s\n',docFiles(k).sourceInfo.docName));
    writeLog(logFile,sprintf('START prepare  %s  (%s)', ...
      docFiles(k).sourceInfo.docName,docFiles(k).sourceFile));

    try
      if isFunction(docFiles(k)) || isClass(docFiles(k))
        text = generateScript(docFiles(k),options);
      else
        text = read(docFiles(k).sourceFile);

        % extract author
        [startIndex,endIndex] = regexp(text,'% Author: .*?\n');
        docFiles(k).sourceInfo.author = text(startIndex+10:endIndex);
        text(startIndex:endIndex) = [];

        % globally replace formulas, tables, etc.
        text = globalReplacements(text,options);
      end

    catch err
      %disptmp(newline);
      system(['touch ' docFiles(k).sourceFile]);
      dispPerm(['  Error preparing <a href="matlab: edit(''' ...
        docFiles(k).sourceFile ''')">',docFiles(k).sourceInfo.docName '</a>']);
      disp(err.message);
      disp(' ');
      writeLog(logFile,sprintf('ERROR prepare  %s  (%s)\n%s', ...
        docFiles(k).sourceInfo.docName,docFiles(k).sourceFile, ...
        getReport(err,'extended','hyperlinks','off')));
      nErrors = nErrors + 1;
      continue
    end

    fid = fopen(target,'w');
    if fid > 0
      fwrite(fid,text);
      fclose(fid);
    end

    writeLog(logFile,sprintf('OK prepare  %s',docFiles(k).sourceInfo.docName));

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
  writeLog(logFile,sprintf('START publish  %s  (%s)', ...
    docFile.sourceInfo.docName,docFile.sourceFile));

  % update xml file
  stylePath = fileparts(pubSettings.stylesheet);

  try
          
    evalin('base','clear variables'); close all;
    evalin('base','format short');

    % reset plotting convention
    pC = plottingConvention;
    pC.makeDefault;

    rng(2,"twister"); % ensure we always have the same random numbers
    
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
      % remove overview png
      pngFile = fullfile(options.outDir,[targetName '.png']);
      if exist(pngFile,'file'), delete(pngFile); end      
      
      % crop all images
      pngTarget = fullfile(options.outDir,[targetName '*.png']);
      if ~isempty(dir(pngTarget))
        unix(['mogrify -trim ' pngTarget]);
      end
    
      % move image files to new directory
      attache = dir(fullfile(options.outDir,[targetName '*.*']));
      for n=1:numel(attache)
        newFile = fullfile(options.outDir,attache(n).name);
        oldFile = fullfile(options.imageDir,regexprep(attache(n).name,targetName,docFile.sourceInfo.docName));

        if exist(oldFile,"file")
          try
            [A,map] = imread(newFile);
            if numel(map)>1, A = ind2rgb(A,map); end
            [B,map] = imread(oldFile);
            if numel(map)>1, B = ind2rgb(B,map); end
            
            if all(size(A)==size(B))
              keep = norm(double(A-B),"fro") / norm(double(A),"fro")  > 0.05;
            else

              fftA = abs(fft2(A)) ./ numel(A);
              fftB = abs(fft2(B)) ./ numel(B);
              s = round(min([size(fftA);size(fftB)])/2.1);
        
              delta1 = norm(fftA(1:s(1),1:s(2),:)-fftB(1:s(1),1:s(2),:),"fro") / ...
                norm(fftA(1:s(1),1:s(2),:),"fro");

              [~,delta2] = imregcorr(B,A);

              keep = delta1 > 5e-2 && delta2 < 0.6;
            end
          catch
            keep = true;
          end
          %[delta1,delta2]

        else
          keep = true;
        end

        if keep
          movefile(newFile,oldFile,'f');
        else
          delete(newFile);
        end
      end
    end

    writeLog(logFile,sprintf('OK publish  %s',docFile.sourceInfo.docName));

  catch e

    success = false;

    % remove
    delete([options.outDir filesep 'script_*'])
    %disptmp('');
    system(['touch ' docFile.sourceFile]);
    dispPerm(['  Error publishing <a href="matlab: edit(''' ...
      docFile.sourceFile ''')">',docFile.sourceInfo.docName '</a>']);

    f = find(strncmp(docFile.targetTemporary,{e.stack.name},length(docFile.targetTemporary)-2));
    errLoc = '';
    if ~isempty(f)
      stack = e.stack(f);
      dispPerm(['   (in file <a href="matlab: opentoline(''' ...
        docFile.sourceFile ''',' num2str(stack.line(1)) ',0)">' docFile.sourceInfo.name '</a>)']);
      fprintf('   %s\n' ,regexprep(e.message,'[\n\r]',''));
      errLoc = sprintf(' at line %d',stack.line(1));
    end

    writeLog(logFile,sprintf('ERROR publish  %s  (%s)%s\n%s', ...
      docFile.sourceInfo.docName,docFile.sourceFile,errLoc, ...
      getReport(e,'extended','hyperlinks','off')));
    nErrors = nErrors + 1;
    
  end
  
end

if isfield(options,'xmlDom'), mytoolbox.removeChild(node); end
cd(oldDir);

writeLog(logFile,sprintf('==== publish run finished: %d error(s) ====',nErrors));

end

function opt = setDefault(opt,field,value)

if ~isfield(opt,field), opt.(field) = value; end

end

function writeLog(logFile,msg)
% append a timestamped message to the publish log
%
% opens, writes and closes the file for every call (rather than keeping a
% handle open) so entries are flushed to disk immediately - this way the
% log survives even if MATLAB crashes mid-run, instead of only living in
% the command window

fid = fopen(logFile,'a');
if fid > 0
  fprintf(fid,'[%s] %s\n',datestr(now,'yyyy-mm-dd HH:MM:SS'),msg);
  fclose(fid);
end

end