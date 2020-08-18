function [] = MetVed_Calculate_Cabin_Consumption()
%--------------------------------------------------------------------------
% Metved: Emissions from Residential Wood Combustion
%--------------------------------------------------------------------------
% Explanation goes here:
%
% NILU: Jan 2018: Henrik Grythe
%--------------------------------------------------------------------------
global DryWoodFactor Emission_year Ratio text_div EFdata Cab
global fp ec CF Primary Emission_year


fprintf('\n%s\n',text_div)
fprintf('In MetVed_Calculate_Cabin_Consumption\n\n')


% DUMMY TABLE NEEDS INVESTIGATION FOR CABINS
Tweight = table;
Tweight.Label            = [{'Winter'};{'Summer'}];
Tweight.fpCabins         = [1.0; 0.4];
Tweight.UsageRateCabins  = [0.8; 1.0];
Tweight.t2mWRange        = [repmat(0.3,2,1)]

% Extract the position of the year for EF and Consumption data:
Ey  = find(EFdata.cab3D == Emission_year);

Tfylke = table;

Tfylke.CabLandsdel = unique(extractfield(Cab,'LandsdelsNR'))';
% Check that it matches the fylkes in the GeoFile:

% Extract the existing fylkes number in the file:
fprintf('Using dry Wood Factor of: %f \n',DryWoodFactor)
Cons1D = squeeze(EFdata.cabCON(:,:,Ey))*DryWoodFactor;
EF1D   = array2table(squeeze(EFdata.cabEF(:,:,Ey)')');
spec   = EFdata.cab2D;
EF1D.Properties.VariableNames = spec;

LandsdelNr    = EFdata.cab1D;
LandsdelNavn  = EFdata.cab1Dn;

SLandsdelNr   = unique(extractfield(Cab,'LandsdelsNR'));

% Write out no match Fylkes:
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
% 1st: Loop Fylker to extract Fylke -level statistics
%--------------------------------------------------------------------------
% Create a variable ALL that includes all buildings part of the
% calculations.
y = find(EFdata.cab3D==Emission_year);

% WOOD POTENTIAL OF EACH BUILDING in the Fylke
WOODPOTENTIAL   = zeros(size(Cab));
GridConsumption = zeros(size(Cab));
Consumtion      = table;

for i=1:height(Tn)
    fprintf('\n%s %02i\n',char(Tn.LandsdelNavn(i)),Tn.LandsdelNr(i))
    If   = find(extractfield(Cab,'LandsdelsNR') == Tn.LandsdelNr(i));
    
    if ~isempty(If)
        lCab = Cab(If);
        nHol  = extractfield(lCab,'bui2hol'); nHol(isnan(nHol))=0;
        nHut  = extractfield(lCab,'bui2hut'); nHut(isnan(nHut))=0;
        nCab  = nHol+nHut;
        
        masl  = extractfield(lCab,'MASL'); masl(masl<0)=0;
        coast = extractfield(lCab,'CoastDST');
        t2m   = extractfield(lCab,'t2m');
        
        % Define a wintertime use cabin:
        idh = masl  >   600;% moh
        idc = coast > 40000;
        idt = t2m   < 3;
        idw = idh|idc|idt;
        
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
        
        WOODPOTENTIAL(If) = WeightWood;
        
        Tn.NumHol(i) = nansum(nHol);
        Tn.NumHut(i) = nansum(nHut);
    else
        warning('##No Cabins found in Landsdel: %02i %s\n',Tn.LandsdelNr(i),char(Tn.LandsdelNavn(i)))
        return
    end
    
end
tCab = struct2table(Cab);
tCab.DryWoodCons = WOODPOTENTIAL;
Cab = table2struct(tCab);

totCON = 1e-6*extractfield(Cab,'DryWoodCons');
fprintf('Had  : %5.1f kT \nBurnt: %5.1f kT \nRest : %5.1f kT \n',nansum(Tn.ConsTot),nansum(totCON),nansum(Tn.ConsTot)-nansum(totCON))

end