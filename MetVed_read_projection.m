%--------------------------------------------------------------------------
% This file is part of MetVed
% 
% MetVed is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation version 3.
% 
% MetVed is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with MetVed.  If not, see <https://www.gnu.org/licenses/>.
%--------------------------------------------------------------------------
function prj = read_projection_MetVed(shapefileName)
% Summary of this function goes here
%   Detailed explanation goes here

if exist(sprintf('%s%s',shapefileName,'.prj'))
    fid  = fopen(sprintf('%s%s',shapefileName,'.prj'),'r');
    txt = textscan(fid,'%s');
    fclose(fid);
    
elseif strcmp(shapefileName(length(shapefileName)-3:length(shapefileName)),'.prj')
    fprintf('%s\n',shapefileName)
    fid  = fopen(shapefileName,'r');
    txt = textscan(fid,'%s');
    fclose(fid);
    
elseif exist(sprintf('%s%s',shapefileName(1:end-4),'.prj'))
    fprintf(sprintf('%s%s\n',shapefileName(1:end-4),'.prj'))
    fid  = fopen(sprintf('%s%s',shapefileName(1:end-4),'.prj'),'r');
    txt = textscan(fid,'%s');
    fclose(fid);
    
else
    fprintf('%s\n',shapefileName)
    error('file not found')
end

a=char(txt{1,1});
[l,r]=size(a);
prj=[];
for i=1:l
    prj=strcat(prj,a(i,:));
end

end

