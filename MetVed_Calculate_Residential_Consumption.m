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
function [] = MetVed_Calculate_Residential_Consumption()
%--------------------------------------------------------------------------
% Metved: Emissions from Residential Wood Combustion
%--------------------------------------------------------------------------
% Explanation goes here:
%
% NILU: Jan 2018: Henrik Grythe
%--------------------------------------------------------------------------

global DryWoodFactor Emission_year Ratio text_div EFdata Res
global fp ec CF Primary Emission_year

fprintf('\n%s\n',text_div)
fprintf('In MetVed_Calculate_Residential_Consumption\n\n')

% Extract the position of the year for EF and Consumption data:
Ey  = find(EFdata.res3D ==Emission_year);

Tfylke = table;

Tfylke.ResFylker = unique(extractfield(Res,'FylkesNR'))';
% Check that it matches the fylkes in the GeoFile:

% Extract the existing fylkes number in the file:
fprintf('Using dry Wood Factor of: %f \n',DryWoodFactor)
Cons1D = squeeze(EFdata.resCON(:,:,Ey))*DryWoodFactor;
EF1D   = array2table(squeeze(EFdata.resEF(:,:,Ey)')');
spec   = EFdata.res2D;
EF1D.Properties.VariableNames=spec;

FylkeNr    = EFdata.res1D;
FylkesNavn = EFdata.res1Dn;
SFylkeNr   = unique(extractfield(Res,'FylkesNR'));

% Write out no match Fylkes:
Tn =[];
for i =1: height(Tfylke)
    T = table;
    idx = find(FylkeNr == Tfylke.ResFylker(i));
    if ~isempty(idx)
        T.FylkeNavn(i) = FylkesNavn(idx);
        T.FylkeNr(i)   = FylkeNr(idx);
        T.ConsTot(i)   = Cons1D(idx,1);
        Tn = [Tn;[T(i,:),EF1D(idx,:)]];
    else
       fprintf('WARNING! No consumption for Fylke %i\n',Tfylke.ResFylker(i)) 
    end
end

MetVed_extract_dwelling_dependencies()

%--------------------------------------------------------------------------
% 1st: Loop Fylker to extract Fylke -level statistics
%--------------------------------------------------------------------------
% Create a variable ALL that includes all buildings part of the
% calculations.

ALL =[extractfield(Res,'dwe_det');extractfield(Res,'dwe_2dw');extractfield(Res,'dwe_row');extractfield(Res,'dwe_mult')]';
y = find(EFdata.res3D==Emission_year);
% WOOD POTENTIAL OF EACH BUILDING in the Fylke
WOODPOTENTIAL   = zeros(size(Res));
GridConsumption = zeros(size(Res));
LOLA_Frac       = zeros(size(Res));

Consumtion = table;
for i=1:length(FylkeNr)
    If  = find(extractfield(Res,'FylkesNR')==FylkeNr(i));
    Ifc = find(EFdata.res1D==FylkeNr(i));
    Ify = find(fp.fn==(FylkeNr(i)));
    fprintf('%s \n',char(FylkesNavn(i)))
    if isempty(If) || isempty(Ifc) ||  isempty(Ify)
        fprintf('Something went wrong for FylkeNr %i \n',FylkeNr(i))
        fprintf('\tFylkeNr %i , #HouseGrids: %i \n',FylkeNr(i),length(If))
        fprintf('\tFylkeNr %i , #EFdata: %i \n',FylkeNr(i),Ifc)
        fprintf('\tFylkeNr %i , #HouseSTats: %i \n',FylkeNr(i),Ify)
        fprintf('MISSING data\n%s\n',text_div)
    else       
        % Here we apply 3 correction factors for building type and for 
        % Multiplier = 1+fraction of fireplaces that are primary heating mechanisms
        Multiplier(i,:) = 1+ Ratio*((([fp.ENE(Ify),fp.TWO(Ify),fp.ROW(Ify),fp.APA(Ify)].*nansum(ALL(If,:)).*Primary))/...
            sum([fp.ENE(Ify),fp.TWO(Ify),fp.ROW(Ify),fp.APA(Ify)].*nansum(ALL(If,:))));
        
        % Calculate the number of consumption units per fylke (N_CU_F)
        Consumption.TotalUnits(i)   = sum([fp.ENE(Ify),fp.TWO(Ify),fp.ROW(Ify),fp.APA(Ify)].*nansum(ALL(If,:)).*Multiplier(i,:).*CF(i,:));        
        fprintf('Consumption Units : %i Units\n',round(Consumption.TotalUnits(i)))
        
        % Consumption per Consumption unit. (kg) per house type (1-4)
        Consumption.per_Unit(i) = 1e6*EFdata.resCON(Ifc,1,y)./Consumption.TotalUnits(i);
        fprintf('Consumption per Unit : %i kg\n',round(Consumption.per_Unit(i)))
        
        % GRIDDED WOOD POTENTIAL
        wooduse = [fp.ENE(Ify)*ALL(If,1)*Multiplier(i,1).*CF(Ify,1),fp.TWO(Ify)*ALL(If,2)*Multiplier(i,2).*CF(Ify,2),...
        fp.ROW(Ify)*ALL(If,3)*Multiplier(i,3).*CF(Ify,3),fp.APA(Ify)*ALL(If,4)*Multiplier(i,4).*CF(Ify,4)];
        
        WOODPOTENTIAL(If)   = nansum(wooduse,2);
        LOLA_Frac(If)       = (WOODPOTENTIAL(If)-max(0,wooduse(:,4)))./WOODPOTENTIAL(If);
        GridConsumption(If) =  WOODPOTENTIAL(If)*Consumption.per_Unit(i);
    
        fprintf('Dealt wood to FylkeNr %s: %4.1f kTon of : %4.1f kTon \n',char(FylkesNavn(i)),round(sum(GridConsumption(If)))*1e-6,EFdata.resCON(Ifc,1,y))
    end
end
fprintf('Adding WOODPOTENTIAL and Grid Consumption to shape...\n...')
T = struct2table(Res);
T.WOODPOTENTIAL   = WOODPOTENTIAL;
T.SmallHouseFrac  = LOLA_Frac;
fprintf('Drying wood!!!...\n...')
T.GridConsumption = GridConsumption*DryWoodFactor;
Res = table2struct(T);
fprintf('Done\n')


end
