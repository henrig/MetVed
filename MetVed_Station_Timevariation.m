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
function [TV,S] = MetVed_Station_Timevariation(S,HDDfile)
%--------------------------------------------------------------------------
% Metved: Emissions from Residential Wood Combustion
%--------------------------------------------------------------------------
% Function to calculate the woodburning timevariation
% takes a matlab dateformatted array (uses start and end)
% and returns an Hourly emission function in the Hours in-between.
% Henrik Grythe -Dec.2017  -NILU, Kjeller
% Henrik Grythe -Aug.2020  -NILU, Kjeller
%--------------------------------------------------------------------------
global Emission_year debug_mode utmTo Htres Cabin_Population_file opath
% S = TotEm; S = shaperead('/storage/nilu/Inby/Emission_Group/Emission_Models/MetVed/MetVed_v2/Output/MetAll_Emissions_nEF_2020')
dn      = datenum([Emission_year,1,1,0,0,0]):1:datenum([Emission_year+1,1,0,0,0,0]);
stepOut = 1/24;
dnew    = min(dn):stepOut:max(dn)+1-stepOut;
dv      = datevec(dnew);

fprintf('First Hour starting: %s\n',datestr(min(dnew),'yyyy-mmm-dd HH:MM'))
fprintf('Last  Hour starting: %s\n',datestr(max(dnew),'yyyy-mmm-dd HH:MM'))
fprintf('Getting School and Bank Holidays for: %s\n',datestr(max(dnew),'yyyy'))
% Get CALENDAR with Holidays
Calendar = Cabin_population(dn(1),Cabin_Population_file);

%--------------------------------------------------------------------------
% First clean the input data and calculate the HDD, should include if
% not working use secondary station.

fprintf('Reading Stations & Data from HDDfile\n...\n')
if Emission_year > 2018
    St        = readtable(HDDfile,'Sheet',sprintf('Stations_%i',Emission_year));
    SD        = readtable(HDDfile,'Sheet',sprintf('Data_%i',Emission_year));
else
    St        = readtable(HDDfile,'Sheet',sprintf('Stations'));
    SD        = readtable(HDDfile,'Sheet',sprintf('Data'));
end

if ~isempty(find(ismember(SD.Properties.VariableNames,'Date')))
    Odv       = datevec(SD.Date+ 693960);
    SD        = SD(Odv(:,1) == Emission_year,:);
    SD.Date   = SD.Date+ 693960;
elseif ~isempty(find(ismember(SD.Properties.VariableNames,'Tid_norskNormaltid_')))
    SD.Date  = datenum(SD.Tid_norskNormaltid_,'dd.mm.yyyy');
    Odv       = datevec(SD.Date);
    SD        = SD(Odv(:,1) == Emission_year,:);
else
    
end



if isempty(SD)
    fprintf('No Station data for year: %i\n',Emission_year)
    TV = NaN;
    return
end
if ~isempty(find(ismember(SD.Properties.VariableNames,'St_no')))
    uID = unique(SD.St_no);
elseif ~isempty(find(ismember(SD.Properties.VariableNames,'Stasjon')))
    tID  = SD.Stasjon;
    SD.St_no   = str2num(char(regexprep(tID,'SN','')));
    uID = unique(SD.St_no);
    St.Stnr = str2num(char(regexprep(St.ID,'SN','')));
    % St.Name = St.NAME; 
else
end
% Extract stations with enough observation days:
nSD = table;
nSt = table;
for i=1:length(uID)
    found = SD(SD.St_no==uID(i) & ~isnan(SD.TAM),:);
    st    = find(St.Stnr==uID(i));
    if height(found)>300 && ~isempty(st)
        if debug_mode
            fprintf(' Using observation: %i %s\t',uID(i),char(St.Name(st(1))))
            fprintf(' Data points at this station %i\n',height(found))
        end
        % Gap fill missing days 
        found = SD(SD.St_no==uID(i),:);

        nfound = table;
        nfound.Date     = dn';
        nfound.St_no(:) = found.St_no(1);
        nfound.TAM(:)   = NaN;
        nfound.TAN(:)   = NaN;
        nfound.TAX(:)   = NaN; 
        [ci, ai, bi] = intersect(nfound.Date,found.Date);
        nfound.TAM(ai) = found.TAM(bi);
        nfound.TAN(ai) = found.TAN(bi);
        try
            nfound.TAX(ai) = found.TAX(bi);
        catch
          nfound.TAX(ai) = found.TAx(bi);
        end
        nSD = [nSD;nfound];
        nSt = [nSt;St(st,:)];
    else
        
        fprintf('%6i %s\t',uID(i),char(St.Name(st)))
        warning(sprintf('Not enough data at this station %i Data threshold set to 300 days',height(found)))
    end
end

fprintf('Transforming to UTM %iN coordinates\n',utmTo)
[x,y,~,~]   = wgs2utm(nSt.Latitude,nSt.Longitude,utmTo,'N');

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %temporary
% for i =1:length(x)
% STAT(i).Geometry = 'Point';
% STAT(i).X        = x(i);
% STAT(i).Y        = y(i);
% STAT(i).ID       = nSt.Stnr(i);
% STAT(i).Year     = Emission_year;
% end


fprintf('Finding each Grids closest Station \n...')
Nearest_Station = zeros(1,length(S));
for i=1:length(S)
    cpx = nanmean(extractfield(S(i),'X'));
    cpy = nanmean(extractfield(S(i),'Y'));
    % regular euclidian distance
    distance = sqrt((x-cpx).^2+(y-cpy).^2)*1e-3; % km
    st       = find(distance==min(distance));
    Nearest_Station(i) = nSt.Stnr(st(1));
    if rem(i,10000)==0; fprintf('.'); end
end
% NOT WORKING CORRECTLY
% [S(1:end).Nearest_Station] = deal(Nearest_Station');
% USE INSTEAD:
T = struct2table(S);
T.Nearest_Station = Nearest_Station';
S = table2struct(T);


fprintf(' Done \n')

% update the unique station ID's to only include the ones with data.
uID = unique(Nearest_Station);

% Adjusted Fit to the SSB data Finstad et al 2001.
week_day = [0.44,0.33,0.23,0.14,0.06,0.01,0.02,0.02,0.02,0.04,0.07,0.16,0.25,0.37,0.49,0.61,0.72,0.83,0.91,0.96,0.96,0.91,0.80,0.55];
week_end = [0.44,0.36,0.26,0.17,0.11,0.20,0.21,0.22,0.24,0.26,0.28,0.30,0.34,0.44,0.55,0.68,0.80,0.88,0.96,1.00,1.00,0.94,0.84,0.60];

% The weekday variation monday to sunday
week = [1,sum(week_end)/sum(week_day),sum(week_end)/sum(week_day)];

% Calcu
for i = 1:length(uID)
    OBS = inpaint_nans(nSD.TAM(nSD.St_no==uID(i)));
    D   = max(Htres-OBS,0);
    
    % Specific test to cut off some multiples of data present in 2018 data.
    DD  = D(1:min(length(dn),length(OBS)));
    
    wHDD(i,:) = DD/sum(DD);

    % independent addon a function for HDD 
    HDD(:,i) =DD;
    TMP(:,i) =OBS(1:min(length(dn),length(OBS)));
    
    % Calculate Daily Residential Weekday&HDD weight
    dwRes(i,:) = week(Calendar.Cabin_day).*wHDD(i,:);
    dwRes(i,:) = dwRes(i,:)/sum(dwRes(i,:));
    
    % Calculate Daily Summer Cabin Weekday&HDD weight
    dwSum(i,:) = Calendar.PopWeight_Summer'.*wHDD(i,:);
    dwSum(i,:) = dwSum(i,:)/sum(dwSum(i,:));
    
    % Calculate Daily Winter Cabin Weekday&HDD weight
    dwWin(i,:) = Calendar.PopWeight_Winter'.*wHDD(i,:);
    dwWin(i,:) = dwWin(i,:)/sum(dwWin(i,:));
end


% independendent addon a function for HDD
THDD = array2table(HDD);
TOBS = array2table(TMP);
for i = 1:length(uID)
    THDD.Properties.VariableNames(i) = {sprintf('SN%i',uID(i))};
    TOBS.Properties.VariableNames(i) = {sprintf('SN%i',uID(i))};
end

%writetable(THDD,sprintf('%s%s_%i.csv','DailyHDDat_Stations',opath,Emission_year))
%writetable(TOBS,sprintf('%s%s_%i.csv','DailyTANat_Stations',opath,Emission_year))
writetable(THDD,sprintf('%s%s_%i.csv',opath,'DailyHDDat_Stations',Emission_year))
writetable(TOBS,sprintf('%s%s_%i.csv',opath,'DailyTANat_Stations',Emission_year))
%--------------------------------------------------------------------------
% Make a timevariation that corresponds with Residential and the two types
% of cabins for each station.
fprintf('Making Hourly Variations\n...\n')
TV = timetable('RowTimes',datetime(datevec(dnew)));
%TV.DateTime = datetime(datevec(dnew));
for st = 1:length(uID)
    fprintf('%i, ',uID(st))
    for i =1:length(dnew)
        date_vec = datevec(dnew(i));
        d        = datetime(date_vec);
        doy      = day(d,'dayofyear');
        
        if Calendar.Cabin_day(doy) == 1
            hwRes(i,st) = dwRes(st,doy)*week_day(date_vec(4)+1);
        else
            hwRes(i,st) = dwRes(st,doy)*week_end(date_vec(4)+1);
        end
        hwSum(i,st) = dwSum(st,doy)*week_end(date_vec(4)+1);
        hwWin(i,st) = dwWin(st,doy)*week_end(date_vec(4)+1);
    end
    if rem(st,15)==0; fprintf('\n St %i/%i : ',st,length(uID)); end
    TV.hwRes = (hwRes(:,st)/sum(hwRes(:,st)));
    TV.hwSum = hwSum(:,st)/sum(hwSum(:,st));
    TV.hwWin = hwWin(:,st)/sum(hwWin(:,st));
    idx = find(ismember(TV.Properties.VariableNames,'hwRes'));
    TV.Properties.VariableNames(idx) = {sprintf('R%i',uID(st))};
    idx = find(ismember(TV.Properties.VariableNames,'hwSum'));
    TV.Properties.VariableNames(idx) = {sprintf('S%i',uID(st))};
    idx = find(ismember(TV.Properties.VariableNames,'hwWin'));
    TV.Properties.VariableNames(idx) = {sprintf('W%i',uID(st))};
end
fprintf('\n',uID(st))

%writetimetable(TV,sprintf('%s_%i.csv',ofiles.TV,Emission_year))
end







