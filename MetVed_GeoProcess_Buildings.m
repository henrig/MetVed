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
function [Sout] = MetVed_GeoProcess_Buildings(S)
%--------------------------------------------------------------------------
% Metved: Emissions from Residential Wood Combustion
%--------------------------------------------------------------------------
% Function is part of the MetVed model and uses global parameters defined
% in MetVed_control.
% Check for a set of fields MetVed wants is present, and if not 
% NILU: Jun 2020: Henrik Grythe
%--------------------------------------------------------------------------
global MunicpalGeoFile CountyGeoFile LandGeoFile TopographyFile CoastLineFile AnnualTempFile CityAreaFile UrbanAreaFile
global text_div
fprintf('\n%s\n',text_div)
fprintf('In MetVed_GeoProcess_Buildings\n\n')

if ~isfield(S,'KommuneNR')
    K = shaperead(MunicpalGeoFile);
    S  = MetVed_Add_location_code_to_BuildingsShape(K,S);
end

if ~isfield(S,'FylkesNR')
    K = shaperead(CountyGeoFile);
    S  = MetVed_Add_location_code_to_BuildingsShape(K,S);
end

if ~isfield(S,'LandsdelsNR')
    K = shaperead(LandGeoFile);
    S  = MetVed_Add_location_code_to_BuildingsShape(K,S);
end

if ~isfield(S,'MASL')
    T = shaperead(TopographyFile);
    S  = MetVed_Add_Grid_Elevation(S,T);
end

if ~isfield(S,'CoastDST')
    T = shaperead(CoastLineFile);
    S  = MetVed_Add_Grid_DistanceToCoast(S,T);
end

if ~isfield(S,'t2m')
    T = shaperead(AnnualTempFile);
    S  = MetVed_Add_Grid_AnnualTemp(S,T);
end

if ~isfield(S,'CityDST')
    T = shaperead(CityAreaFile);
    S  = MetVed_Add_Grid_DistanceToCity(S,T);
end

if ~isfield(S,'UrbanDST')
    T = shaperead(UrbanAreaFile);
    S  = MetVed_Add_Grid_DistanceToUrban(S,T);
end


Sout = S;
end

