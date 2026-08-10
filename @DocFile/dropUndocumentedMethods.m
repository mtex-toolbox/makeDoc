function [files,dropped] = dropUndocumentedMethods(files)
% remove class methods that have no help comment of their own
%
% A method without a leading comment block is not undocumented as far as
% MATLAB is concerned: |help| falls back to the documentation of the built-in
% function of the same name, so |S1FunHandle/numel.m| gets the help of |numel|
% and |SO3TangentVector/unique.m| the one of |unique|. The published page then
% describes MATLAB instead of MTEX, down to an example section of
% |openExample| calls - which are code and get executed while publishing.
%
% Only methods are dropped. A class definition or a plain function without a
% help comment has nothing to inherit, and dropping it would take a landing
% page such as |tensor.tensor| or |pfSections| out of the reference.
%
% Syntax
%   files = dropUndocumentedMethods(files)
%   [files,dropped] = dropUndocumentedMethods(files)
%
% Output
%  files   - the remaining @DocFiles
%  dropped - doc names of the removed methods, as a cell array
%
% See also
% DocFile/hasOwnHelp DocFile/exclude DocFile/select

% docName is Class.name for everything in an @-folder, so the class
% definition itself comes out as tensor.tensor
isMethod = false(size(files));
for k = 1:numel(files)
  parts = regexp(files(k).sourceInfo.docName,'\.','split');
  isMethod(k) = numel(parts) == 2 && ~strcmp(parts{1},parts{2});
end

out = ~isMethod | hasOwnHelp(files);

dropped = cell(1,sum(~out));
k = find(~out);
for i = 1:numel(k), dropped{i} = files(k(i)).sourceInfo.docName; end

files = files(out);
