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
function [Sout] = MetVed_Add_Grid_DistanceToCoast(S,T)
% MetVed_Add_Grid_Elevation function calculates an approximate elevation of
% each grid cell in a shape file of norway, by coupling it to an elevation
% file. The elevation is then added as a field in the snhapefile "MASL" -
% Metres Above Sea Level.
% Function assumes equal projection.
%--------------------------------------------------------------------------
global text_div
fprintf('\n%s\n',text_div)
fprintf('In MetVed_Add_Grid_DistanceToCoast\n\n')


Ftype = S(1).Geometry;
fprintf('Geometry found for houses = %s\n',Ftype)
if ~ismember(Ftype,{'Point'})
    fprintf('Calculating Grid center (meanX meanY) \n')
    try
        for i= 1:length(S)
            x(i) = nanmean(extractfield(S(i),'X'));
            y(i) = nanmean(extractfield(S(i),'Y'));
        end
    catch
        for i= 1:length(S)
            x(i) = nanmean(extractfield(S(i),'x'));
            y(i) = nanmean(extractfield(S(i),'y'));
        end
    end
else
    try
        x = extractfield(S,'X');
        y = extractfield(S,'Y');
    catch
        x = extractfield(S,'x');
        y = extractfield(S,'y');
    end
end

Ftype = T(1).Geometry;
fprintf('Geometry found for Topography = %s\n',Ftype)

if ismember(Ftype,{'Line'})
    AVST = 1e9*ones(size(x));
    for i=1:length(T)
        for j=1:length(x)
            dst(j) = min(sqrt((x(j)-T(i).X).^2 + (y(j)-T(i).Y).^2));
        end
        if rem(i,100)==0; fprintf('Processed: %8i of %i  \n',i, length(T)); end
        AVST=min(AVST,dst);
    end
end
st = struct2table(S);
st.CoastDST = AVST';
S = table2struct(st);

Sout = S;
end
% prj = 'PROJCS["SWEREF99_TM",GEOGCS["GCS_SWEREF99",DATUM["D_SWEREF99",SPHEROID["GRS_1980",6378137,298.257222101]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]],PROJECTION["Transverse_Mercator"],PARAMETER["latitude_of_origin",0],PARAMETER["central_meridian",15],PARAMETER["scale_factor",0.9996],PARAMETER["false_easting",500000],PARAMETER["false_northing",0],UNIT["Meter",1]]';
% dbf = makedbfspec(Sout);
% shapewrite(Sout,'Buildings_With_CoastDST','DbfSpec',dbf)
% pfilename = strcat('Buildings_With_Elevation','.prj');
% fid       = fopen(pfilename,'w+');
% fprintf(fid,'%s',prj);
% fclose(fid);
%

