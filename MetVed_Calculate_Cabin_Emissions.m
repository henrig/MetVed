function [S] = MetVed_Calculate_Cabin_Emissions()
%--------------------------------------------------------------------------
% Metved: Emissions from Cabin Wood Combustion 
%--------------------------------------------------------------------------
% Function combines Emission Factors for all species that were defined in
% the SSB sheet with gridded consumption. The gridded consumption is 
% calculatet in MetVed. This calculates an annual emission for each grid.
% Function uses global MetVed variables 
%    Cab            : Struct  : cabin grid with field DryWoodCons 
%    Emission_year  : Integer : Year of calculation
%    EFData         : Struct  : Strucured Emission data from SSB
%
% NILU   : Jan 2018: Henrik Grythe 
% Revised: Aug 2020: Henrik Grythe 
%--------------------------------------------------------------------------
global EFdata Cab Emission_year text_div

fprintf('\n%s\n',text_div)
fprintf('In MetVed_Calculate_Cabin_Emissions\n\n')

LandsdelNr = unique(extractfield(Cab,'LandsdelsNR'));
Yr         = find(EFdata.cab3D==Emission_year);

Emissions = zeros(size(Cab,1),size(EFdata.cabEF,2));
for i =1:length(LandsdelNr)
    If = find(extractfield(EFdata,'cab1D')==LandsdelNr(i));
    Il = find(extractfield(Cab,'LandsdelsNR')==LandsdelNr(i));    
    fprintf('Landsdel %i Cabins: %i \n',LandsdelNr(i),length(Il))
    if ~isempty(If)
        for c = 1:size(EFdata.cabEF,2)
            Emissions(Il,c) = EFdata.cabEF(If,c,Yr)*extractfield(Cab(Il),'GridConsumption')';
            Fname(c) = {sprintf('gEM_%s',char(EFdata.cab2D(c)))};
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

% For Cabins all are expected to have the same Emission height.
T.EmH(:) = 15; 

S = table2struct(T);
end