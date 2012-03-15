function deadlink(docFiles,outputDir)

% html_path = fullfile(mtex_path,'help','html');
html_path = outputDir;
files = dir(fullfile(html_path,'*.html'));
% html_page = {files.name};

% ug_files = get_ug_files(fullfile(mtex_path,'help'));
check = struct;
for file=docFiles
  htmlFile = fullfile(outputDir,[file.sourceInfo.docName '.html']);
  
  if exist(htmlFile)
    html = read(htmlFile);
    source = read(file);
    links = regexp(html,'(href=")(?<href>\S*?)(.html")','names');
    lineBreak = regexp(source,'\n');
    
    for k=1:numel(links)
      found = strfind(source,[links(k).href '.html']);
      
      if ~exist(fullfile(html_path,[links(k).href '.html']))
        for l=1:numel(found)
          check(end+1).reference = links(k).href;
          check(end).inFile = file.sourceFile;
          check(end).inFileShort = file.sourceInfo.name;
          check(end).inLine = sum(lineBreak<found(l))+1;
        end
      end
    end
    
    
  end
  %   page
  %   html_file = fullfile(html_path,  page{:});
  %   link = regexp(file2cell(html_file),'(href=")(?<href>\S*?)(.html")','names');
  %   for line = find(~cellfun('isempty',link))
  %     for href = {link{line}.href}
  %       if ~any(~cellfun('isempty',strfind(html_page, href{1})))
  %         p = regexprep(page{:},'.html','');
  %         if ~exist(p,'file')
  %           ug = get_ug_filebytopic(ug_files,'test');
  %           if ~isempty(ug)
  %             p = ug;
  %           else
  %             p = regexprep(p,'_','/');
  %           end
  %         end
  %
  %         if isempty(href{1})
  %            s = ['EMPTY LINK -> <a href="' html_file '">' page{:}  ...
  %              '</a> -> (<a href="matlab:edit ' p '">' p '.m</a>)' ];
  %         else
  %           s = ['<a href="' html_file '">' page{:}  '</a> -> (<a href="matlab:edit ' p '">' p '.m</a>)' ...
  %             ' -> link: '  href{1} ];
  %         end
  %         disp(s)
  %       end
  %     end
  %   end
end
% check


wzrd = figure('MenuBar','none',...
  'Resize','off',...
  'Name','DocFiles',... 'Resize','off',...
  'NumberTitle','off',...
  'tag','docFileViewer',...
  'Color',get(0,'defaultUicontrolBackgroundColor'),...
  'Position',[100 100 200 500]);

wrzd_list = uicontrol('parent',wzrd,...
  'style','listbox',...
  'position',[0 0 200 500],...
  'backgroundcolor','white',...
  'fontsize',10,...
  'max',2,...
  'tag','docFileList');


for k=1:numel(check)
  list{k} = ['<HTML><FONT color="black">' check(k).inFileShort  '</FONT> <FONT color="blue">' check(k).reference '</FONT></HTML>'];
end

set(wrzd_list,'String',list)


set(wrzd_list,'Callback',{@fileChanged,check})


function fileChanged(src,evt,check)

pos = get(src,'value');

opentoline(check(pos).inFile,check(pos).inLine);

figure(gcbf);











