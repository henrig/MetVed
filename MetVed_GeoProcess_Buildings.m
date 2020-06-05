function [Sout] = MetVed_GeoProcess_Buildings(S)
%--------------------------------------------------------------------------
% Metved: Emissions from Residential Wood Combustion
%--------------------------------------------------------------------------
% Function is part of the MetVed model and uses global parameters defined
% in MetVed_control.
% NILU: Jun 2020: Henrik Grythe
%--------------------------------------------------------------------------
global MunicpalGeoFile CountyGeoFile LandGeoFile TopographyFile CoastLineFile 

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
    S  = MetVed_Add_Grid_Elevation(S,T);
end



end

