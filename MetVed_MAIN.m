%--------------------------------------------------------------------------
% Metved: Emissions from Residential Wood Combustion 
%--------------------------------------------------------------------------
% Explanation goes here: 

% NILU: Jan 2018: Henrik Grythe
% NILU: Jun 2020: Henrik Grythe 
%--------------------------------------------------------------------------
% 
fprintf('In MetVed_MAIN\n\n')
% add needed global fields
global EFdata tfiles Res Cab
global use_temporary_files do_Residential do_Cabins

% MAIN
MetVed_check_Input()

[EFdata]  = MetVed_Import_SSB_Consumption_and_EF;

[Res,Cab] = MetVed_Import_Buildingfiles;

if do_Residential
    Res = MetVed_GeoProcess_Buildings(Res);
    if use_temporary_files
        save(tfiles(1),'Res')
    end
end

if do_Cabins
    Cab = MetVed_GeoProcess_Buildings(Cab);
    if use_temporary_files
        save(tfiles(2),'Cab')
    end
end


% MetVed Stuff v
if do_Residential
    MetVed_Calculate_Residential_Consumption()
    MetVed_Calculate_Residential_Emissions()
end
% MetCab Stuff v
if do_Cabins


end

