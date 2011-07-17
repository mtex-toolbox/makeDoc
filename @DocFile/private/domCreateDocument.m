function [dom,document] = domCreateDocument(doc,attributes)

if nargin < 1
  error('needs a document root')
end

dom = com.mathworks.xml.XMLUtils.createDocument(doc);
document = dom.getDocumentElement();

if nargin > 1
  for k=1:2:numel(attributes)
    document.setAttribute(attributes{k},attributes{k+1});
  end
end
