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
global EFdata tfiles
global use_temporary_files do_Residential do_Cabins debug_mode

% MAIN
MetVed_check_Input()

[EFdata] = MetVed_Import_SSB_Consumption_and_EF;

[Res Cab] = MetVedImport_Buildingfiles;

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



% MetCab Stuff v
