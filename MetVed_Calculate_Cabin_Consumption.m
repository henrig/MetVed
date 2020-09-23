function [] = MetVed_Calculate_Cabin_Consumption()
%--------------------------------------------------------------------------
% Metved: Emissions from Cabin Wood Combustion in Norway
%--------------------------------------------------------------------------
% The total cabin consumption is taken from SSB. This consumption is
% distributed to each cabin according to its specific properties. We
% distinguish cabins by their location, which nclude altitude, distance to
% the coast and mean annual Temperature in 2019. 
% Each cabin grid is evaluated by each of the parameters to determine
% whether it is a SUMMER or WINTER cabin. The effect of this 
%
% NILU: Jan 2018: Henrik Grythe
% NILU: Aug 2020: Henrik Grythe
%--------------------------------------------------------------------------
global DryWoodFactor Emission_year EFdata Cab text_div

fprintf('\n%s\n',text_div)
fprintf('In MetVed_Calculate_Cabin_Consumption\n\n')

% DUMMY TABLE NEEDS TO BE DEFINED OUTSIDE FUNCTION
Tweight = table;
Tweight.Label            = [{'Winter'};{'Summer'}];
Tweight.fpCabins         = [1.0; 0.4];
Tweight.UsageRateCabins  = [0.8; 1.0];
Tweight.t2mWRange        = [0.3; NaN];
Tweight.maslTresh        = [400; NaN]; % 600
Tweight.coastalTresh     = [15;  NaN]; % 40
Tweight.tempTresh        = [2;   NaN]; % 3

fprintf('Table used for internal Cabin weighting \n for consumption distribution\n')
disp(Tweight)

% Extract the position of the year for EF and Consumption data:
Ey                 = find(EFdata.cab3D == Emission_year);
Tfylke             = table;
Tfylke.CabLandsdel = unique(extractfield(Cab,'LandsdelsNR'))';

% Extract the existing Geographical number in the file and the correct years
% consumption. 
fprintf('Using dry Wood Factor of: %f \n',DryWoodFactor)
Cons1D        = squeeze(EFdata.cabCON(:,:,Ey))*DryWoodFactor;
EF1D          = array2table(squeeze(EFdata.cabEF(:,:,Ey)')');
spec          = EFdata.cab2D;
EF1D.Properties.VariableNames = spec;
LandsdelNr    = EFdata.cab1D;
LandsdelNavn  = EFdata.cab1Dn;
SLandsdelNr   = unique(extractfield(Cab,'LandsdelsNR'));

% Check that it matches the Landsdeler in the GeoFile:
% Write out no match Landsedeler:
Tn =[];
for i =1: height(Tfylke)
    T = table;
    idx = find(LandsdelNr == Tfylke.CabLandsdel(i));
    if ~isempty(idx)
        T.LandsdelNavn(i) = LandsdelNavn(idx);
        T.LandsdelNr(i)   = LandsdelNr(idx);
        T.ConsTot(i)      = Cons1D(idx,1);
        Tn = [Tn;[T(i,:),EF1D(idx,:)]];
    else
        fprintf('WARNING! No consumption for Fylke %i\n',Tfylke.CabLandsdel(i))
    end
end
%--------------------------------------------------------------------------
% Pre set WOOD POTENTIAL OF EACH BUILDING in the Fylke to zeros.
WOODUSE         = zeros(size(Cab));
CABINTYPE       = zeros(size(Cab));
GridConsumption = zeros(size(Cab));
Consumtion      = table;

% Loop through each geographical region (Landsdel) for wich consumption is
% defined.
for i=1:height(Tn)
    fprintf('\n%s %02i\n',char(Tn.LandsdelNavn(i)),Tn.LandsdelNr(i))
    If   = find(extractfield(Cab,'LandsdelsNR') == Tn.LandsdelNr(i));
    
    if ~isempty(If)
        % If there are Cabins in this Geographical area, Proceed to extract
        % the relevant fields, for determiningt Grid consumption.
        lCab = Cab(If);
        nHol  = extractfield(lCab,'bui2hol'); nHol(isnan(nHol))=0;
        nHut  = extractfield(lCab,'bui2hut'); nHut(isnan(nHut))=0;
        nCab  = nHol+nHut;
        
        % Define a wintertime use cabin, by the Thresholds:
        masl  = extractfield(lCab,'MASL'); masl(masl<0)=0;
        coast = extractfield(lCab,'CoastDST');
        t2m   = extractfield(lCab,'t2m');        
        idh = masl  > Tweight.maslTresh(1)        ;% moh
        idc = coast > Tweight.coastalTresh(1)*1e3 ;% km -> m
        idt = t2m   < Tweight.tempTresh(1);        % Celsius
        idw = idh|idc|idt;
        
        % Write out some statistics
        mT = mean(t2m.*nCab)/(mean(nCab));
        fprintf('Units Hut: %5i  Hol: %5i CabTot: %5i ConsTot: %3.1f kT\n',nansum(nHut),nansum(nHol),sum(nCab),Tn.ConsTot(i))
        fprintf('Coast min: %5i mean: %5i    max: %5i km \n',round(min(coast)/1000),round(mean(coast.*nCab)/(1000*mean(nCab))),round(max(coast)/1000))
        fprintf('Masl. min: %5i mean: %5i    max: %5i m.a.s.l. \n',round(min(masl)),round(mean(masl.*nCab)/(mean(nCab))),round(max(masl)))
        fprintf('Temp. min: %5i mean: %5i    max: %5i C \n',round(min(t2m)),round(mean(t2m.*nCab)/(mean(nCab))),round(max(t2m)))
        fprintf('Average consumption: %5.1f kg \n',1e6*Tn.ConsTot(i)/sum(nCab))
        fprintf('Winter cabins: %5.1f %% \n',100*sum(nCab(idw))/sum(nCab))

        % Calculate a weighted z-score from normalized data.
        nT = t2m-min(t2m);
        nT = nT/max(nT);
        nT = 1-Tweight.t2mWRange(1)*normalize(t2m);
        
        % For each Grid calculate Wood Potential according to the type of
        % cabins in each grid.
        clear wp CABType WeightWood

        for j=1:length(lCab)
            %wp = N_cabins*
            if idw(j)
                idx = find(contains(Tweight.Label,'Winter'));
                wp(j) = nCab(j)*Tweight.fpCabins(idx)*Tweight.UsageRateCabins(idx)*max(nT(j),0.2);
                CABType(j) = 2;
            else
                idx = find(contains(Tweight.Label,'Summer'));
                wp(j) = nCab(j)*Tweight.fpCabins(idx)*Tweight.UsageRateCabins(idx)*max(nT(j),0.2);
                CABType(j) = 1;
            end
        end
        WeightWood     = 1e6*Tn.ConsTot(i)*(wp/sum(wp));
        
        iw = CABType==2;
        is = CABType==1;
        AW = sum(WeightWood(iw))/sum(nCab(iw));
        AS = sum(WeightWood(is))/sum(nCab(is));
        fprintf('Average consumption: %5.1f kg WINTER \n',AW)
        fprintf('Average consumption: %5.1f kg SUMMER \n',AS)
        fprintf('R: %5.2f WINTER/SUMMER \n',AW/AS)
        
        WOODUSE(If)       = WeightWood;
        CABINTYPE(If)     = CABType;
        
        Tn.NumHol(i) = nansum(nHol);
        Tn.NumHut(i) = nansum(nHut);
    else
        warning('##No Cabins found in Landsdel: %02i %s\n',Tn.LandsdelNr(i),char(Tn.LandsdelNavn(i)))
        return
    end
    
end
% Tabelize the struct for easy 
tCab = struct2table(Cab);
tCab.GridConsumption = WOODUSE;
tCab.CabType         = CABINTYPE;

Cab = table2struct(tCab);
% Check that all wood has been burnt!
totCON = 1e-6*extractfield(Cab,'GridConsumption');
fprintf('Had  : %5.1f kT \nBurnt: %5.1f kT \nRest : %5.1f kT \n',nansum(Tn.ConsTot),nansum(totCON),nansum(Tn.ConsTot)-nansum(totCON))

end