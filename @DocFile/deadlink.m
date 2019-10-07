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
          disp(['<a href="matlab:opentoline(''' ...
            file.sourceFile ''',' int2str(sum(lineBreak<found(l))+1) ')">' ...
            file.sourceInfo.name ' -> ' links(k).href '</a>'])
        end
      end
    end
  end
end
