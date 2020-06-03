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
fprintf('In MetVed_check_Input\n\n')
% paths:
global pname ipath opath tpath  
% files:
global MunicpalGeoFile CountyGeoFile LandGeoFile TopographyFile CoastLineFile 
global SSBfile OvenDensity HouseSizes HouseEnergy ResidentialFile
global text_div 
%--------------------------------------------------------------------------
global ifiles

% Test folders existence
if exist(pname,'dir')~=7 &&  exist(ipath,'dir')~=7 &&  exist(tpath,'dir')~=7
    error('not an existing folder')
else
    fprintf('MetVed will run in Folder: %s\n',pname)
    fprintf('MetVed input Folder:       %s\n',ipath)
    fprintf('MetVed uses Temp Folder:   %s\n',ipath)
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
ifiles = cell(10,1);
ifiles(1)  = {MunicpalGeoFile};
ifiles(2)  = {CountyGeoFile};
ifiles(3)  = {LandGeoFile};
ifiles(4)  = {TopographyFile};
ifiles(5)  = {CoastLineFile};
ifiles(6)  = {SSBfile};
ifiles(7)  = {OvenDensity};
ifiles(8)  = {HouseSizes};
ifiles(9)  = {HouseEnergy};
ifiles(10) = {ResidentialFile};

% Check the files if they exist. If they do not exist do not keepo their
% names.
for i=1:length(ifiles)
    tmp = exist(char(ifiles(i)),'file');
    if tmp ~=2
       warning(sprintf('Non existent input file \n %s\n',char(ifiles(i))) )
       ifiles(i)={'empty'};
    end
end




end
