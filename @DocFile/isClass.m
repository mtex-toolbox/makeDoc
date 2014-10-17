function isCl = isClass(file)
% checks whether docFile is a class file
%
%% Input
% file   - a @DocFile
%
%% Output
% isCl  - |true| / |false| 

str = read(file);

isCl = any(strfind(str,'classdef'));
