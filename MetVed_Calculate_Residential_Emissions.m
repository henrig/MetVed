function [S] = MetVed_Calculate_Residential_Emissions()
%--------------------------------------------------------------------------
% Metved: Emissions from Residential Wood Combustion 
%--------------------------------------------------------------------------
% Explanation goes here: 
% 
% NILU: Jan 2018: Henrik Grythe 
%--------------------------------------------------------------------------
global EFdata Res Emission_year text_div

fprintf('\n%s\n',text_div)
fprintf('In MetVed_Calculate_Residential_Emissions\n\n')

% unit conversion
KGtoTON =1e-3;
GtoTON  =1e-6;

% Load the shape 
T = struct2table(Res);

FylkeNr = unique(extractfield(Res,'FylkesNR'));
Year = find(EFdata.res3D==Emission_year);


Emissions = zeros(size(Res,1),size(EFdata.resEF,2));
for i =1:length(FylkeNr)
    If = find(extractfield(EFdata,'res1D')==FylkeNr(i));
    if ~isempty(If)
        for c= 1:size(EFdata.resEF,2)
            Emissions(If,c) = EFdata.resEF(If,c,Year)*extractfield(Res(If),'GridConsumption')';
            Fname(c) = {sprintf('EM_%s(g)',char(EFdata.res2D(c)))};
        end
    else
        fprintf('Something went wrong for FylkeNr %i \n',FylkeNr(i))
        fprintf('\tFylkeNr %i , #HouseGrids: %i \n',FylkeNr(i),length(If))
        fprintf('\tFylkeNr %i , #EFdata: %i \n',FylkeNr(i),i)
        fprintf('\tFylkeNr %i , #HouseSTats: %i \n',FylkeNr(i),i)
        fprintf('MISSING data\n%s\n',text_div)
 
    end
end

T   = [T,array2table(Emissions)];
T.EmH = (T.SmallHouseFrac*15) + ((1-T.SmallHouseFrac)*30);
idx = find(contains(T.Properties.VariableNames,'Emissions'));
T.Properties.VariableNames(idx) = Fname;
S   = table2struct(T);
end
    

