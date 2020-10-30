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
function [] = MetVed_WriteShape(S,PrjFile,ofname)
%--------------------------------------------------------------------------
% Metved: Emissions from Residential Wood Combustion
%--------------------------------------------------------------------------
% Explanation goes here:
%
% NILU: Aug 2020: Henrik Grythe
%--------------------------------------------------------------------------
global text_div
fprintf('\n%s\n',text_div)
fprintf('In MetVed_WriteShape\n\n')

dbfspec = makedbfspec(S);
shapewrite(S, ofname, 'DbfSpec', dbfspec)
prj = MetVed_read_projection(PrjFile);
pfilename=strcat(ofname,'.prj');
fid=fopen(pfilename,'w+');
fprintf(fid,'%s',prj);
fclose(fid);
fprintf('Wrote file; \n %s \n',ofname)

end
