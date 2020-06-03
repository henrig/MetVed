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
global SSBfile OvenDensity HouseSizes HouseEnergy ResidentialFile

% Test folders existence
if exist(pname,'dir')~=7 &&  exist(ipath,'dir')~=7 &&  exist(tpath,'dir')~=7
    error('not an existing folder')
else
    fprintf('MetVed will run in Folder: \n%s\n',pname)
    fprintf('MetVed input Folder:       \n%s\n',ipath)
    fprintf('MetVed uses Temp Folder:   \n%s\n',ipath)
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
ifile(1)  = {MunicpalGeoFile};
ifile(2)  = {CountyGeoFile};
ifile(3)  = {LandGeoFile};
ifile(4)  = {TopographyFile};
ifile(5)  = {CoastLineFile};
ifile(6)  = {SSBfile};
ifile(7)  = {OvenDensity};
ifile(8)  = {HouseSizes};
ifile(9)  = {HouseEnergy};
ifile(10) = {ResidentialFile};

% Check the files if they exist. If they do not exist do not keepo their
% names.
for i=1:length(ifile)
    tmp = exist(ifile(i),'file');
    if tmp ~=2
       warning(sprintf('Non existent input file \n %s\n',ifile(i)) )
       ifile(i)={''};
    end
end




end
