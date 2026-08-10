function out = hasOwnHelp(files)
% does the file carry a help comment of its own?
%
% A method without a leading comment block is not undocumented as far as
% MATLAB is concerned: |help| falls back to the documentation of the built-in
% function of the same name, so |S1FunHandle/numel.m| gets the help of |numel|
% and |SO3TangentVector/unique.m| the one of |unique|. Publishing that yields a
% reference page describing MATLAB rather than MTEX - and its example section
% consists of |openExample| calls, which are code and would be executed while
% publishing.
%
% The help of a file is either the comment block right in front of the
% |function| / |classdef| line or the one right after it; if neither is there,
% whatever <DocFile.generateScript.html generateScript> gets hold of comes from
% somewhere else.
%
% Syntax
%   files = files(hasOwnHelp(files))
%
% Input
%  files - a list of @DocFiles
%
% Output
%  out   - logical, one entry per file
%
% See also
% DocFile/exclude DocFile/select

out = true(size(files));

for k = 1:numel(files)

  lines = regexp(read(files(k)),'\n','split');
  lines = strtrim(lines);
  lines = lines(~cellfun('isempty',lines));
  if isempty(lines), out(k) = false; continue; end

  % a comment before the declaration is the help as well
  if lines{1}(1) == '%', continue; end

  decl = find(~cellfun('isempty', ...
    regexp(lines,'^(function|classdef)\W','once')),1);

  % no declaration at all: a script, which is its own documentation
  if isempty(decl), continue; end

  % the declaration itself may be continued over several lines, as in
  % classdef (InferiorClasses = {?SO3FunBingham, ...
  while decl < numel(lines) && endsWith(lines{decl},'...')
    decl = decl + 1;
  end

  out(k) = decl < numel(lines) && lines{decl+1}(1) == '%';

end
