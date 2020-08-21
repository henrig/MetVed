%--------------------------------------------------------------------------
% Metved: Emissions from Residential & Cabin Wood Combustion in Norway
%--------------------------------------------------------------------------
% MetVed uses a control sheet to set and define global variables, input
% paths, files and output along with some options. MAIN Loop for MetVed.
% Controls the sequence and checks inputs. The primary reading routines are
% called from MAIN. The parameter sheet, "Control" can either be called
% from main or vice versa to run the model. 
% 
% This version of MetVed can calculate either both Cabin emissions and
% Residential emissions, combine them or separately. It First calculates
% annual emissions for one year, but also have associated functions for
% timevariation and 

% NILU: Jan 2018: Henrik Grythe
% NILU: Aug 2020: Henrik Grythe 
%--------------------------------------------------------------------------


fprintf('\n%s\n',text_div)
fprintf('In MetVed_MAIN\n\n')

% MAIN
MetVed_check_Input()

[EFdata]  = MetVed_Import_SSB_Consumption_and_EF;

[Res,Cab] = MetVed_Import_Buildingfiles;

if do_Residential
    fprintf('\n%s\nResidential Buildings \n%s\n',text_div,text_div)
    Res = MetVed_GeoProcess_Buildings(Res);
    if use_temporary_files
        save(tfiles.Residential,'Res')
        fprintf('Saved a new version of %s\n',tfiles.Residential)
    end
end

if do_Cabins
    fprintf('\n%s\n Cabins \n%s\n',text_div,text_div)
    Cab = MetVed_GeoProcess_Buildings(Cab);
    if use_temporary_files
        save(tfiles.Cabins,'Cab');  fprintf('Saved a new version of %s\n',tfiles.Cabins)
    end
end


% MetVed  v
if do_Residential
    if use_temporary_files
        save(tfiles.Residential,'Res')
        fprintf('%sSaved a new version of %s\n%s\n',text_div,tfiles.Residential,text_div)
    end
    MetVed_Calculate_Residential_Consumption()
    ResEm =MetVed_Calculate_Residential_Emissions();
    ofname = sprintf('%s_%i',ofiles.Residential,Emission_year);
    dbfspec=makedbfspec(ResEm);
    shapewrite(ResEm, ofname, 'DbfSpec', dbfspec)
    prj = MetVed_read_projection(ResFile);
    pfilename=strcat(ofname,'.prj');
    fid=fopen(pfilename,'w+');
    fprintf(fid,'%s',prj);
    fclose(fid);
end
% MetCab  v
if do_Cabins
    if use_temporary_files
        save(tfiles.Cabins,'Cab');  fprintf('Saved a new version of %s\n',tfiles.Cabins)
    end

    MetVed_Calculate_Cabin_Consumption()
    CabEm = MetVed_Calculate_Cabin_Emissions();
    ofname = sprintf('%s_%i',ofiles.Cabins,Emission_year);
    dbfspec=makedbfspec(CabEm);
    shapewrite(CabEm, ofname, 'DbfSpec', dbfspec)
    
    prj = MetVed_read_projection(CabFile);
    pfilename=strcat(ofname,'.prj');
    fid=fopen(pfilename,'w+');
    fprintf(fid,'%s',prj);
    fclose(fid);
end

[S] = MetVed_Combine_Emissions()
