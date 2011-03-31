function content = getTableOfContent(files , format,dom)
% produces a summary html-table for given doc-files
%
%% Input
% format - 'short','toc'


if nargin < 2,
  format = 'short';
end

[dom,table] = domCreateDocument('table',{'class','ref','width','90%'});

for docFile=files
  docName = docFile.sourceInfo.docName;
  
  switch lower(format)
    case 'short'
      shortDescription = getShortDescription(docFile);
      if ~isempty(shortDescription)
        tr = domAddChild(dom,table,'tr');
        addHeadingCell(dom,tr,shortDescription,docName);
      end
    case 'toc'
      cellDescription = getCellDescription(docFile);
      if ~isempty(cellDescription)
        tr = domAddChild(dom,table,'tr');
        addToggleExpander(dom,tr,docName);
        addHeadingCell(dom,tr,cellDescription,docName);
        
        tr = domAddChild(dom,table, 'tr');
        addSubHeadingCell(dom,tr,cellDescription,docName);
      end
      
  end
  
end

if nargin  < 3
  % web(xslt(dom,'D:\workspace\mtex\mtex_svn\help\makeHelp\style\publishmtex.xsl'))
  content = xmlwrite(dom);
  content = regexprep(content(40:end),'\n( *)</a>','</a>');
else
  content = dom;
end


function content = getShortDescription(docFile)


[ifun] = isFunction(docFile);

if ifun
  text = helpfunc(docFile.sourceFile);

  endPattern = '(?=\n %|\n[ ]*\n[ ]*|\n[ ]*$)';
  text = regexp(text,['(.*?)' endPattern],'match');
  if ~isempty(text)
    summary = regexprep(strtrim(text{1}),'^[ ]*|\n[ ]*',' ');
  else
    summary = '';
  end
  
  content.title = docFile.sourceInfo.name;
  content.summary = summary;
else
  text = read(docFile);
  content = regexp(text,'^%%(?<title>.*?)\n(?<summary>.*?)(?=%%|$)','names');
  content.summary = strtrim(regexprep(content.summary,'%',''));  
  
   % somehow xsl link transformation fails
  content.title = regexprep(content.title,'\[\[(.*?),(.*?)\]\]','$2'); 
end



function contents = getCellDescription(file)

% read source
text = read(file);

% markup title and summary
regularTitlePattern   = '%% (?<title>(.*?))\n';
regularSummaryPattern = '(?<summary>(.*?))(?=(%%|\n[ ]+|\n(?!%)))';
emptyTitlePattern     = '%%[ ]*\n';
wholePattern          = [regularTitlePattern '|' regularTitlePattern regularSummaryPattern '|' emptyTitlePattern];
contents = regexp(text,wholePattern,'names');

for k=1:numel(contents)
  if ~isfield(contents(k),'summary')
    contents(k).summary = '';
  end
  
  if ~isempty(contents(k).summary)
    contents(k).summary = regexprep(contents(k).summary,'(?>%[ ]*)|\n','');
  end
end


function s = badKeyword
s = {'Abstract','Contents','Open in Editor','See also','View Code'};


function td = addToggleExpander(dom,tr,docName)

td = domAddChild(dom,tr,'td',[],{'valign','top','width','15'});
div = domAddChild(dom,td,'div',[],{'align','center'});
a = domAddChild(dom,div,'a',[],...
  {'href','#',...
  'onClick', ['return toggleexpander(''', docName, '_block'',''', docName, '_expandable_text'');'],...
  'valign','top',...
  'width','15'});

% img =
domAddChild(dom,a,'img',[],...
  {'style','border:0px',...
  'id', [docName, '_expandable_text'],...
  'src','arrow_right.gif'});


function addHeadingCell(dom,tr,cellDescription,docName)

td = domAddChild(dom,tr, 'td',[],{'valign','top','width','250px'});

a = domAddChild(dom,td,'a',cellDescription(1).title,{'href',[docName '.html']} );
domAddChild(dom,a,'td',cellDescription(1).summary,{'valign','top','width','75%'});


function td = addSubHeadingCell(dom,tr,cellDescription,docName)

td = domAddChild(dom,tr, 'td');
td = domAddChild(dom,tr, 'td',[],{'colspan','2'});

div = domAddChild(dom,td, 'div',[],...
  {'style','display:none; background:#e7ebf7; padding-left:2ex;',...
  'id',[docName, '_block'],...
  'class','expander'});

subtable = domAddChild(dom,div, 'table',[]);

for k=2:numel(cellDescription)
  if ~isempty(cellDescription(k).title) && ~any(strcmpi(cellDescription(k).title,badKeyword))
    subtr = domAddChild(dom,subtable, 'tr',[]);
    
    td = domAddChild(dom,subtr, 'td');
    a = domAddChild(dom,td,'a',cellDescription(k).title,{'href',[docName '.html' '#' num2str(k)]} );
  end
end






