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
function [Res,Cab] =  MetVed_Import_Buildingfiles()
%--------------------------------------------------------------------------
% Metved: Emissions from Residential Wood Combustion
%--------------------------------------------------------------------------
% Explanation goes here:
% Options for global parameters set in MetVed_Control.
% Lookup for residential files in folder. These are geoprocessed files that
% come in the SSB grid and has been PreProcessed into shapefiles by the
% preprocessing script: 
%
% NILU: Jan 2018: Henrik Grythe
% NILU: Jun 2020: Henrik Grythe
%--------------------------------------------------------------------------

global ifiles tfiles Residentialpath CabinHousepath Emission_year
global do_Residential do_Cabins use_temporary_files text_div
global ResFile CabFile
fprintf('\n%s\n',text_div)
fprintf('In MetVed_Import_Buildingfiles\n\n')

tf = cell(1,1);
%--------------------------------------------------------------------------
if do_Residential
    fprintf('Fetching Residential Buildings\n\n')   
    ResFile = sprintf('%sAll_Dwellings_%04i',Residentialpath,Emission_year);
    a       = length(ifiles);
    yearlim = 50;
    i = 1;
    fprintf('%s\n',ResFile)
    while ~exist(strcat(ResFile,'.shp')) && i < yearlim
        ResFile = sprintf('%sAll_Dwellings_%04i',Residentialpath,Emission_year-i);
        i=i+1;
    end
    fprintf('%s\n',ResFile)
    if i >= yearlim
        fprintf('Year %i out of bounds\n', Emission_year)
        Res =[];
        return
    end
    if i>1; warning(sprintf('No Residential file for year %i \n using closest found %i ',Emission_year,Emission_year-i+1)); pause; end
    
    if use_temporary_files
        ce = split(ResFile,'/');
        try
            tf = strcat('Temp/',char(ce(end)),'.mat');
            fprintf('Checking to load temporary file from :%s\n',tf)
            load(tf)
            fprintf('Loaded\n')
            tfiles.Residential = tf; 
        catch
            fprintf('### No file found from :%s\n',tf)
            ifiles(a+1) = {ResFile};
            fprintf('Reading large file ...')
            Res = shaperead(ResFile);
            fprintf('Done\n')
            save(tf,'Res')
        end
    else
        ifiles(a+1) = {ResFile};
        fprintf('Reading large file ...')
        Res = shaperead(ResFile);
        fprintf('Done\n')
    end

else
    Res =[];
end
%--------------------------------------------------------------------------
if do_Cabins
    fprintf('Fetching Cabins\n\n')  
    CabFile = sprintf('%sCabins_Only_%04i',CabinHousepath,Emission_year);
    a = length(ifiles);
    yearlim = 50;
    i = 1;
    while ~exist(strcat(CabFile,'.shp')) && i < yearlim
        CabFile = sprintf('%sAll_Dwellings_%04i',Residentialpath,Emission_year-i);
        i=i+1;
    end
    if i >= yearlim
        fprintf('Year %i out of bounds\n', Emission_year)
        Cab =[];
        return
    end
    if i>1; warning(sprintf('No Residential file for year %i \n using closest found %i ',Emission_year,Emission_year-i+1)); end
    
    if use_temporary_files
        ce = split(CabFile,'/');
        try
            tf = strcat('Temp/',char(ce(end)),'.mat');
            fprintf('Checking to load temporary file from :%s\n',tf)
            load(tf)
            tfiles.Cabins =tf;
        catch
            fprintf('### No file found in Temp\n')
            ifiles(a+1) = {CabFile};
            fprintf('Reading large file ...')
            Cab = shaperead(CabFile);
            fprintf('Done\n')
            save(tf,'Cab')
        end
    else
        ifiles(a+1) = {CabFile};
        fprintf('Reading large file ...')
        Cab = shaperead(CabFile);
        fprintf('Done\n')
    end
    
else
    Cab =[];
end


end