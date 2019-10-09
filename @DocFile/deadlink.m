function deadlink(docFiles,outputDir)

% html_path = fullfile(mtex_path,'help','html');
if ~iscell(outputDir), outputDir = {outputDir}; end

for file=docFiles
  
  htmlFile = fullfile(outputDir,[file.sourceInfo.docName '.html']);
  path2file = cellfun(@exist,htmlFile);
    
  if any(path2file)
    htmlFile = htmlFile{find(path2file,1)};
    html = read(htmlFile);
    source = read(file);
    links = regexp(html,'(href=")(?<href>\S*?)(.html")','names');
    lineBreak = regexp(source,'\n');
    
    for k=1:numel(links)
      found = strfind(source,[links(k).href '.html']);
      
      if ~any(cellfun(@(path) exist(fullfile(path,[links(k).href '.html'])),outputDir))
        for l=1:numel(found)                    
          disp(['<a href="matlab:opentoline(''' ...
            file.sourceFile ''',' int2str(sum(lineBreak<found(l))+1) ')">' ...
            file.sourceInfo.name ' -> ' links(k).href '</a>'])
        end
      end
    end
  end
end
