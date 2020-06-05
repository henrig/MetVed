function [EFdata] = MetVed_Import_SSB_Consumption_and_EF()
%--------------------------------------------------------------------------
% Metved: Emissions from Residential Wood Combustion
%--------------------------------------------------------------------------
% Function is part of the MetVed model and uses global parameters defined
% in MetVed_control.
%--------------------------------------------------------------------------
% This function reads and structures the tables that come out of SSB API or
% the SSB webpage. It assumes the structure of the SSB tables 9703-3 and
% 9704.4 and an additional emission factor sheet that is added. The
% function looks for 4 categories of consumption and ties them with
% emission factors for "Open" = 2, "New" = 3 and Old =  4, RWC emission
% factors. Numerical assosiation is in accordance with SSB.
%
%
%
% NILU: Jun 2020: Henrik Grythe
%--------------------------------------------------------------------------
global SSBfile debug_mode do_Cabins do_Residential text_div
fprintf('\n%s\n',text_div)
fprintf('In MetVed_Import_SSB_Consumption_and_EF\n\n')

% Four categories of consumption is assumed.
FP_type=[{'ALL'},{'Open'},{'Old'},{'New'}];

ResSheet = '9703-3';
CabSheet = '9704-3';
EFSheet  = 'EF';

% Check file for correct sheets
try
    ImportOptions = detectImportOptions(SSBfile,'Sheet',ResSheet);
    ImportOptions.VariableNamesRange='A4';
    ImportOptions.DataRange='A5';
    Tres =readtable(SSBfile,ImportOptions);
catch
    fprintf('Warning; residental consumption sheet not found\n')
    do_Residential = 0;
end
try
    ImportOptions = detectImportOptions(SSBfile,'Sheet',CabSheet);
    ImportOptions.VariableNamesRange='A4';
    ImportOptions.DataRange='A5';
    Tcab =readtable(SSBfile,ImportOptions);
catch
    fprintf('Warning; cabin consumption sheet not found\n')
    do_Cabins = 0;
end
try
    Tef  = readtable(SSBfile,'Sheet',EFSheet);
    hlEF = Tef.Properties.VariableNames;
    fprintf('\tReading EF sheet         : %s\n',EFSheet)
catch
    fprintf('ERROR: No Emission Factors found\n')
    return
end
fprintf('In file \n%s\n',SSBfile)

if do_Residential
    %----------------------------------------------------------------------
    fprintf('\n*RESIDENTIAL\n')
    %----------------------------------------------------------------------
    % Read Norwegian counties of the file
    fprintf('\tReading Residential sheet: %s\n',ResSheet)
    FylkesNavn = Tres.Fylkesnavn(1:4:end);
    FylkeNr    = Tres.Fylkesnr(1:4:end);
    c          = unique(Tres.Teknologinr);
    % Find available years by looping years between 1900 and 2200
    t = 1;
    for yyyy = 1900:2200
        ty          = ismember(Tres.Properties.VariableNames,{sprintf('x%04i',yyyy)});
        if sum(ty) == 1
            y(t) = yyyy; yi(t) = find(ty); t= t+1;
        end
    end
    fprintf('Found Consumption data for %i Years %i--%i\n',length(y),min(y),max(y))
    
    % Write out available species in EF file.
    fprintf('Emission Factors for:  ')
    for comp = 1:height(Tef)
        fprintf('%s, ',char(table2cell(Tef(comp,1))))
    end
    fprintf('\n')
    
    % Loop through years and copute each regions EF for that year for all
    % components EFres will be 3D:: EFres(County, Species, Year). We only
    % use consumption by technology.
    clear Cons EFres
    for i=1:length(FylkeNr)
        TF = Tres(Tres.Fylkesnr==FylkeNr(i),:);
        if debug_mode; fprintf('Fylke : %02i %s\n',FylkeNr(i),char(FylkesNavn(i)) ); end
        for yr = 1:length(yi)
            if debug_mode; fprintf('   year : %04i',y(yr)); end
            for Tech = 1:length(c)
                TFT             = TF(TF.Teknologinr==Tech,:);
                Cons(i,Tech,yr) = table2array(TFT(:,yi(yr)));
                tmp(Tech)       = TFT.Teknologi;
            end
            R = (Cons(i,2,yr)+Cons(i,3,yr)+Cons(i,4,yr))/Cons(i,1,yr);
            if R<0.9 || R>1.1; fprintf('Ceck inconsistent data: C: %s Y: %i %2.1f\n', char(FylkesNavn(i)),y(yr),R); end
            for comp = 1:height(Tef)
                Efac             = Tef(comp,:);
                EFres(i,comp,yr) = ( table2array(Efac(1,contains(hlEF,'Open')))*Cons(i,2,yr) + ...
                    table2array(Efac(1,contains(hlEF,'Old')))*Cons(i,4,yr)+ ...
                    table2array(Efac(1,contains(hlEF,'New')))*Cons(i,3,yr) )/nansum(Cons(i,2:4,yr),2);
                if debug_mode; fprintf('%6.2f   ',EFres(i,comp,yr)); end
            end
            if debug_mode; fprintf('\n'); end
        end
    end
    % Store outdata in struct.
    EFdata.resCON  = Cons;
    EFdata.resEF   = EFres;
    EFdata.res1Dn  = FylkesNavn;
    EFdata.res1D   = FylkeNr;
    EFdata.res2D   = table2cell(Tef(:,1));
    EFdata.res3D   = y;
    fprintf('Found Emission Factors (EF) for \n%i Fylker \n%i Compounds \n%i Years\n',size(EFres))
end

if do_Cabins
    %--------------------------------------------------------------------------
    fprintf('\n*CABINS\n')
    %--------------------------------------------------------------------------
    fprintf('\tReading Cabin sheet      : %s\n',CabSheet)
    clear y yi
    % Read Norwegian county parts of the file
    FylkesNavn = Tcab.landsdel(1:4:end);
    FylkeNr    = 1:length(FylkesNavn);
    c          = unique(Tcab.Teknologinr);
    Weight     = [1,0.05,0.2,0.75];
    % Find available years by looping years between 1900 and 2200
    t = 1;
    for yyyy = 1900:2200
        ty          = ismember(Tcab.Properties.VariableNames,{sprintf('x%04i',yyyy)});
        if sum(ty) == 1
            y(t) = yyyy; yi(t) = find(ty); t= t+1;
        end
    end
    fprintf('Found Consumption data for %i Years %i--%i\n',length(y),min(y),max(y))
    
    % Write out available species in EF file.
    fprintf('Emission Factors for:  ')
    for comp = 1:height(Tef)
        fprintf('%s, ',char(table2cell(Tef(comp,1))))
    end
    fprintf('\n')
    
    % Loop through years and copute each regions EF for that year for all
    % components EFres will be 3D:: EFres(County, Species, Year). We only
    % use consumption by technology.
    clear Cons EFcab
    for i=1:length(FylkeNr)
        TF = Tcab(ismember(Tcab.landsdel,FylkesNavn(i)),:);
        if debug_mode; fprintf('Fylke : %02i %s\n',FylkeNr(i),char(FylkesNavn(i)) ); end
        for yr = 1:length(yi)
            if debug_mode; fprintf('   year : %04i',y(yr)); end
            for Tech = 1:length(c)
                TFT = TF(TF.Teknologinr==Tech,:);
                Cons(i,Tech,yr) = table2array(TFT(:,yi(yr)));
                if isnan(Cons(i,Tech,yr))
                    Cons(i,Tech,yr)=Cons(i,1,yr)*Weight(Tech);
                end
                tmp(Tech) = TFT.Teknologi;
            end
            for comp = 1:height(Tef)
                Efac = Tef(comp,:);
                EFcab(i,comp,yr) = (table2array(Efac(1,contains(hlEF,'Open')))*Cons(i,2,yr) + ...
                    table2array(Efac(1,contains(hlEF,'Old')))*Cons(i,4,yr)+ ...
                    table2array(Efac(1,contains(hlEF,'New')))*Cons(i,3,yr) )/nansum(Cons(i,2:4,yr),2);
                
                if debug_mode; fprintf('%6.2f   ',EFres(i,comp,yr)); end
            end
            if debug_mode; fprintf('\n'); end
        end
    end
    fprintf('Found Emission Factors (EF) for \n%i Fylker \n%i Compounds \n%i Years\n',size(EFcab))
    % Store outdata in struct.
    EFdata.cabCON    = Cons;
    EFdata.cabEF     = EFres;
    EFdata.cab1Dn    = FylkesNavn;
    EFdata.cab1D     = FylkeNr;
    EFdata.cab2D     = table2cell(Tef(:,1));
    EFdata.cab3D     = y;
end
end
