function b = badKeywords(str)

keywords = {'Open in Editor','View Code','Contents','Abstract'};

b = any(strcmpi(str,keywords));