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

%--------------------------------------------------------------------------
if do_Residential
    fprintf('\n%s\nResidential Buildings \n%s\n',text_div,text_div)
    Res = MetVed_GeoProcess_Buildings(Res);
    if use_temporary_files
        save(tfiles.Residential,'Res')
        fprintf('Saved a new version of %s\n',tfiles.Residential)
    end
    fprintf('%s\nSimulation time elapsed %i min\n%s\n', text_div,round((now-timer)*60*24), text_div)
end

%--------------------------------------------------------------------------
if do_Cabins
    fprintf('\n%s\n Cabins \n%s\n',text_div,text_div)
    Cab = MetVed_GeoProcess_Buildings(Cab);
    if use_temporary_files
        save(tfiles.Cabins,'Cab');  fprintf('Saved a new version of %s\n',tfiles.Cabins)
    end
    fprintf('%s\nSimulation time elapsed %i min\n%s\n', text_div,round((now-timer)*60*24), text_div)
end


%--------------------------------------------------------------------------
% MetVed  v
if do_Residential
    if use_temporary_files
        save(tfiles.Residential,'Res')
        fprintf('%sSaved a new version of %s\n%s\n',text_div,tfiles.Residential,text_div)
    end
    
    MetVed_Calculate_Residential_Consumption()
    ResEm = MetVed_Calculate_Residential_Emissions();
    ofname = sprintf('%s_%i',ofiles.Residential,Emission_year);
    MetVed_WriteShape(ResEm,ResFile,ofname)
    fprintf('%s\nSimulation time elapsed %i min\n%s\n', text_div,round((now-timer)*60*24), text_div)
end
%--------------------------------------------------------------------------
% MetCab  v
if do_Cabins
    if use_temporary_files
        save(tfiles.Cabins,'Cab');  fprintf('Saved a new version of %s\n',tfiles.Cabins)
    end
    
    MetVed_Calculate_Cabin_Consumption()
    CabEm = MetVed_Calculate_Cabin_Emissions();
    ofname = sprintf('%s_%i',ofiles.Cabins,Emission_year);
    MetVed_WriteShape(CabEm,CabFile,ofname)
end

%--------------------------------------------------------------------------
% Merge data if needed
if do_Residential && do_Cabins
    [TotEm] = MetVed_Combine_Emissions();
end

%--------------------------------------------------------------------------
% Timevariation
if do_Residential && do_Cabins
    [TV,S] = MetVed_Station_Timevariation(TotEm,HDDfile);
    ofname = sprintf('%s_%i',ofiles.Total,Emission_year);
    MetVed_WriteShape(S,ResFile,ofname)
elseif do_Residential
    [TV,S] = MetVed_Station_Timevariation(ResEm,HDDfile);
    ofname = sprintf('%s_%i',ofiles.Residential,Emission_year);
    MetVed_WriteShape(ResEm,ResFile,ofname)
else
    [TV,S] = MetVed_Station_Timevariation(CabEm,HDDfile);
    ofname = sprintf('%s_%i',ofiles.Cabins,Emission_year);
    MetVed_WriteShape(S,CabFile,ofname)
end
writetimetable(TV,sprintf('%s_%i.csv',ofiles.TV,Emission_year))

