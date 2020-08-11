function MetVed_check_Input
%--------------------------------------------------------------------------
% Metved: Emissions from Residential Wood Combustion
%--------------------------------------------------------------------------
% Function is part of the MetVed model and uses global parameters defined
% in MetVed_control.
%--------------------------------------------------------------------------
% Test the folders and files existence. This avoids crashing later.
% Function also structs the files and for use with output.
%
%
% NILU: Jun 2020: Henrik Grythe
%--------------------------------------------------------------------------
% paths:
global pname ipath opath tpath  
% files:
global MunicpalGeoFile CountyGeoFile LandGeoFile TopographyFile CoastLineFile 
global SSBfile OvenDensity HouseSizes HouseEnergy
global text_div 
global ifiles prj
%--------------------------------------------------------------------------

fprintf('\n%s\n',text_div)
fprintf('In MetVed_check_Input\n\n')

% Test folders existence
if exist(pname,'dir')~=7 &&  exist(ipath,'dir')~=7 &&  exist(tpath,'dir')~=7
    if exist(pname,'dir')~=7; fprintf('%s',pname);end
    if exist(ipath,'dir')~=7; fprintf('%s',ipath);end
    if exist(tpath,'dir')~=7; fprintf('%s',tpath);end
    error('not an existing folder')
else
    fprintf('MetVed will run in Folder: %s\n',pname)
    fprintf('MetVed input Folder:       %s\n',ipath)
    fprintf('MetVed uses Temp Folder:   %s\n',tpath)
end
fprintf('\n%s\n',text_div)
% Give the option to create the output folder:
if exist(opath,'dir')~=7
    warning('Output folder does not exist!')
    prompt = 'Create? 0=(No) 1=(Yes)';
    ans    = input(prompt);
    if ans
        mkdir(opath)
    else
        error('not an existing folder')
    end
else
    fprintf('MetVed output Folder: \n%s\n',opath)
end
fprintf('\n%s\n',text_div)

% Struct the input file Names for later.
ifiles = cell(9,1);
ifiles(1)  = {MunicpalGeoFile};
ifiles(2)  = {CountyGeoFile};
ifiles(3)  = {LandGeoFile};
ifiles(4)  = {TopographyFile};
ifiles(5)  = {CoastLineFile};
ifiles(6)  = {SSBfile};
ifiles(7)  = {OvenDensity};
ifiles(8)  = {HouseSizes};
ifiles(9)  = {HouseEnergy};

% Check the files if they exist. If they do not exist do not keep their
% names. Add a test for file extension .shp.
for i=1:length(ifiles)
    id  = ~isempty(ifiles{i});
    if id; tmp = exist(char(ifiles{i}),'file'); else; ifiles(i)={'empty'}; end
    if tmp ~=2
        id2 = exist(strcat(char(ifiles(i)),'.shp'));
        if id2~=2
            fprintf('WARNING Non existent input file \n %s\n',char(ifiles(i)))
            ifiles(i)={'empty'};
        end
    end
end

prj = MetVed_read_projection(MunicpalGeoFile);







end
