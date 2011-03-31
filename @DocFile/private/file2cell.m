function str = file2cell(file)

str = read(file);
str = regexp(str,'\n','split');
str = regexprep(str,'\r','');
