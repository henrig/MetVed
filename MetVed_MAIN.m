%--------------------------------------------------------------------------
% Metved: Emissions from Residential Wood Combustion 
%--------------------------------------------------------------------------
% Explanation goes here: 

% NILU: Jan 2018: Henrik Grythe
% NILU: Jun 2020: Henrik Grythe 
%--------------------------------------------------------------------------
% 
% add needed global fields
global EFdata tfiles Res Cab Emission_year ofiles
global use_temporary_files do_Residential do_Cabins Res Cab
global ResFile CabFile

fprintf('\n%s\n',text_div)
fprintf('In MetVed_MAIN\n\n')

% MAIN
MetVed_check_Input()

[EFdata]  = MetVed_Import_SSB_Consumption_and_EF;

[Res,Cab] = MetVed_Import_Buildingfiles;

if do_Residential
    Res = MetVed_GeoProcess_Buildings(Res);
    if use_temporary_files
        save(tfiles.Residential,'Res')
        fprintf('Saved a new version of %s\n',tfiles.Residential)
    end
end

if do_Cabins
    Cab = MetVed_GeoProcess_Buildings(Cab);
    if use_temporary_files
        save(tfiles.Cabins,'Cab');  fprintf('Saved a new version of %s\n',tfiles.Cabins)
    end
end


% MetVed Stuff v
if do_Residential
    MetVed_Calculate_Residential_Consumption()
    MetVed_Calculate_Residential_Emissions()
    
    ofname = sprintf('%s_%i',ofiles.Residential,Emission_year);
    dbfspec=makedbfspec(Res);
    shapewrite(Res, ofname, 'DbfSpec', dbfspec)
    
    prj = MetVed_read_projection(ResFile);
    pfilename=strcat(ofname,'.prj');
    fid=fopen(pfilename,'w+');
    fprintf(fid,'%s',prj);
    fclose(fid);

end
% MetCab Stuff v
if do_Cabins
    %MetVed_Calculate_Cabin_Consumption()
    %MetVed_Calculate_Cabin_Emissions()
    
    ofname = sprintf('%s_%i',ofiles.Cabins,Emission_year);
    dbfspec=makedbfspec(Cab);
    shapewrite(Cab, ofname, 'DbfSpec', dbfspec)
    
    prj = MetVed_read_projection(CabFile);
    pfilename=strcat(ofname,'.prj');
    fid=fopen(pfilename,'w+');
    fprintf(fid,'%s',prj);
    fclose(fid);

end

