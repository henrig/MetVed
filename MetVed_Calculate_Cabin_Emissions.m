function [S] = MetVed_Calculate_Cabin_Emissions()
%--------------------------------------------------------------------------
% Metved: Emissions from Residential Wood Combustion 
%--------------------------------------------------------------------------
% Explanation goes here: 
% 
% NILU: Jan 2018: Henrik Grythe 
%--------------------------------------------------------------------------
global EFdata Cab Emission_year text_div

fprintf('\n%s\n',text_div)
fprintf('In MetVed_Calculate_Cabin_Emissions\n\n')

% unit conversion
KGtoTON = 1e-3;
GtoTON  =1e-6;


LandsdelNr = unique(extractfield(Cab,'LandsdelsNR'));
Yr       = find(EFdata.cab3D==Emission_year);


Emissions = zeros(size(Cab,1),size(EFdata.cabEF,2));
for i =1:length(LandsdelNr)
    If = find(extractfield(EFdata,'cab1D')==LandsdelNr(i));
    Il = find(extractfield(Cab,'LandsdelsNR')==LandsdelNr(i));    
    length(Il)
    if ~isempty(If)
        for c= 1:size(EFdata.cabEF,2)
            Emissions(Il,c) = EFdata.cabEF(If,c,Yr)*extractfield(Cab(Il),'DryWoodCons')';
            Fname(c) = {sprintf('EM_%s(g)',char(EFdata.cab2D(c)))};
        end
    else
        fprintf('Something went wrong for LandsdelNr %i \n',LandsdelNr(i))
        fprintf('\tFylkeNr %i , #HouseGrids: %i \n',LandsdelNr(i),length(If))
        fprintf('\tFylkeNr %i , #EFdata: %i \n',LandsdelNr(i),i)
        fprintf('\tFylkeNr %i , #HouseSTats: %i \n',LandsdelNr(i),i)
        fprintf('MISSING data\n%s\n',text_div)
    end
end
% Load the shape 
T = struct2table(Cab);

T   = [T,array2table(Emissions)];
idx = find(contains(T.Properties.VariableNames,'Emissions'));
T.Properties.VariableNames(idx) = Fname;
%T(1:100,:)



S = table2struct(T);
end