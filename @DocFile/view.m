function view(file,options,success)
% display the source of the DocFile


if nargin > 1
  
  if isstruct(options)
    output = options;
    output.force = true;
    output.viewoutput = false;
    output.outputDir = output.publishSettings.outputDir;
  else
    output.outputDir = options;    
    output.publishSettings.outputDir = options;
    output.force = true;
  end
  
  if nargin < 3
    success = true(size(file));
  end
  
  
  
  list = {};
  link = {};
  files = {};
  
  for k=1:numel(file)
    htmlout{k} = fullfile(output.outputDir,[file(k).sourceInfo.docName '.html']);
    
    if success(k) && exist(htmlout{k})
      list{end+1} = file(k).sourceInfo.docName;
    else
      list{end+1} = ['<HTML><FONT color="red">' file(k).sourceInfo.docName '</FONT></HTML>'];
    end
    
    link{end+1} = htmlout{k};
    files{end+1} = file(k);
    
  end
  
  files = [files{:}];
  
  %   listdlg('ListString',docfile)
  wzrd = findall(0,'tag','docFileViewer');
  if isempty(wzrd)
    wzrd = figure('MenuBar','none',...
      'Resize','off',...
      'Name','DocFiles',... 'Resize','off',...
      'NumberTitle','off',...
      'tag','docFileViewer',...
      'HandleVisibility','off',...
      'Color',get(0,'defaultUicontrolBackgroundColor'),...
      'Position',[100 100 200 500]);
    
    wrzd_list = uicontrol('parent',wzrd,...
      'style','listbox',...
      'position',[0 0 200 500],...
      'backgroundcolor','white',...
      'fontsize',10,...
      'max',2,...
      'tag','docFileList');
    
  else
    wrzd_list = findall(wzrd,'tag','docFileList');
  end
  
  set(wrzd_list, ...
    'String',list,...
    'Callback',{@fileChanged,link},...
    'KeyPressFcn',{@keypressFnc,files});
  
  
  hcmenu = uicontextmenu('parent',wzrd);
  uimenu(hcmenu, 'Label', 'Republish', 'Callback', {@rePublish,wrzd_list,files,false,output});
  uimenu(hcmenu, 'Label', 'Republish eval Code', 'Callback', {@rePublish,wrzd_list,files,true,output});
  uimenu(hcmenu, 'Label', 'Edit Source', 'Callback', {@editSource,wrzd_list,files});
  set(wrzd_list,'uicontextmenu',hcmenu);
  
  set(wrzd_list,'Value',numel(link));
  
  if numel(files) == 1
    web(link{numel(link)});
  end
  figure(wzrd);
  
else
  edit(file.sourceFile);
end


function fileChanged(src,evt,link)

pos = get(src,'value');
web(link{pos});
figure(gcbf);

function keypressFnc(src,evt,files)

pos = get(src,'value');
switch evt.Key
  case 'return'
    editSource([],[],src,files)
end

function editSource(src,evt,list,files)

pos = get(list,'value');
source(files(pos))


function rePublish(src,evt,list,files,eval,output)


pos = get(list,'value');
output.evalCode = eval;
[html_out,success] = publish(files(pos),output);

view(files,output);
% set(list,'Value',pos(1));
% val = get(list,'String');
% for k=1:numel(success)
%   if success(k)
%     val{pos(k)} = files(pos(k)).sourceInfo.name;
%   else
%     val{pos(k)} = ['<HTML><FONT color="red">' files(pos(k)).sourceInfo.name '</FONT></HTML>'];
%   end
% end
% set(list,'String',val);
web(html_out)



function buttonDownFnc(src,evt,files)

% pos = get(src,'value');
% source(files(pos));


