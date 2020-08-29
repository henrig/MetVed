function [S] = MetVed_Calculate_Residential_Emissions()
%--------------------------------------------------------------------------
% Metved: Emissions from Residential Wood Combustion 
%--------------------------------------------------------------------------
% Function to merge grid consumption with EMission factors from struct. The
% function assumes and do a crude test that the Counties of EMission
% factors and Grid consumption adds up, and writes a warning if they fdo
% not.
% 
% NILU: Jan 2018: Henrik Grythe 
%--------------------------------------------------------------------------
global EFdata Res Emission_year DryWoodFactor text_div debug_mode

fprintf('\n%s\n',text_div)
fprintf('In MetVed_Calculate_Residential_Emissions\n\n')


% Tabelize the current residential shape 
T = struct2table(Res);

% Extract from the SSB sheet the Counties
FylkeNr = unique(extractfield(Res,'FylkesNR'));
Year    = find(EFdata.res3D==Emission_year);

Emissions = zeros(size(Res,1),size(EFdata.resEF,2));



% Loop Through the emissions of each county in the file
for i =1:length(FylkeNr)
    
    If = find(extractfield(EFdata,'res1D')==FylkeNr(i));
    fprintf('%s\n',char(EFdata.res1Dn(If)))

    Ib = find(extractfield(Res,'FylkesNR')==FylkeNr(i));
    if ~isempty(If) && ~isempty(Ib)
        Cons = extractfield(Res(Ib),'GridConsumption')';
        fprintf('%6.1f  kTon Wood GridConsumption \n Grids: %i \n',sum(Cons)*1e-6, length(Ib))
        % LOOP species and calcualate emissions.
        for c = 1:size(EFdata.resEF,2)
            Emissions(Ib,c) = EFdata.resEF(If,c,Year)*Cons;
            Fname(c) = {sprintf('gEM_%s',char(EFdata.res2D(c)))};
            if debug_mode
            fprintf('%i: %6.1f EM_%s (kg)  EF %6f g/kg  \n',FylkeNr(i),sum(Emissions(If,c))*1e-3,char(EFdata.res2D(c)),sum(Emissions(Ib,c))/sum(Cons))
            end
        end
        
    else
        fprintf('Something went wrong for FylkeNr %i \n',FylkeNr(i))
        fprintf('\tFylkeNr %i , #HouseGrids: %i \n',FylkeNr(i),length(If))
        fprintf('\tFylkeNr %i , #EFdata: %i \n',FylkeNr(i),i)
        fprintf('\tFylkeNr %i , #HouseSTats: %i \n',FylkeNr(i),i)
        fprintf('MISSING data\n%s\n',text_div)
    end
end
Cons = sum(extractfield(Res,'GridConsumption'));
fprintf('%s\nNorway: %6.1f  kTon Dry Wood Factor (%3f) Wood\n',text_div,sum(Cons)*1e-6,DryWoodFactor)
for c = 1:size(EFdata.resEF,2)
    fprintf('Norway: %2.2e (Ton) EM_%s   EF %6f g/kg \n',sum(Emissions(:,c))*1e-6,char(EFdata.res2D(c)),sum(Emissions(:,c))/Cons)
end



T      = [T,array2table(Emissions)];
T.EmH  = (T.SmallHouseFrac*15) + ((1-T.SmallHouseFrac)*30);
idx    = find(contains(T.Properties.VariableNames,'Emissions'));
T.Properties.VariableNames(idx) = Fname;
fprintf('Structurizing large table...\n%s\n',text_div)
S   = table2struct(T);
fprintf('%s\n',text_div)
end
    

