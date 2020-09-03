function [S] = MetVed_Combine_Emissions()
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
global CabEm ResEm text_div

fprintf('\n%s\n',text_div)
fprintf('In MetVed_Combine_Emissions\n\n')

base = [{'Geometry'},{'BoundingBox'},{'X'},{'Y'},{'SSBID'},{'KommuneNR'},{'FylkesNR'},{'LandsdelsNR'},...
  {'MASL'},{'CoastDST'},{'t2m'},{'CityDST'},{'UrbanDST'}];
rf = fields(ResEm);
cf = fields(CabEm);
uf = unique([rf;cf]);

% Create fields missing in order to be able to concatonate them.
tCab = struct2table(CabEm);
tRes = struct2table(ResEm);
for i=1:length(uf)
    tr = find(ismember(rf,uf(i)));
    if isempty(tr)
        fprintf('Will add field %s to ResEm\n',char(uf(i)))
        tRes.NeWfield(:) = 0;
        fix = find(ismember(tRes.Properties.VariableNames,'NeWfield'));
        tRes.Properties.VariableNames(fix) = uf(i);
    end
    tc = find(ismember(cf,uf(i)));
    if isempty(tc)
        fprintf('Will add field %s to CabEm\n',char(uf(i)))
        tCab.NeWfield(:) = 0;
        fix = find(ismember(tCab.Properties.VariableNames,'NeWfield'));
        tCab.Properties.VariableNames(fix) = uf(i);
    end
end
% Make SSBID numeric
if ismember(class(tRes.SSBID),{'cell'})
    v = str2num(char(tRes.SSBID));
    tRes.SSBID = v;
end
if ismember(class(tCab.SSBID),{'cell'})
    v = str2num(char(tCab.SSBID));
    tCab.SSBID = v;
end
% Deal with some old fields
if isfield(ResEm,'KOMMUNENR')
    if ismember(class(tRes.KOMMUNENR),{'cell'})
        v = str2num(char(tRes.KOMMUNENR));
        tRes.KOMMUNENR = v;
    end
    if ismember(class(tCab.KOMMUNENR),{'cell'})
        v = str2num(char(tCab.KOMMUNENR));
        tCab.KOMMUNENR = v;
    end
end
if isfield(ResEm,'FYLKE')
    if ismember(class(tRes.FYLKE),{'cell'})
        v = str2num(char(tRes.FYLKE));
        tRes.FYLKE = v;
    end
    if ismember(class(tCab.FYLKE),{'cell'})
        v = str2num(char(tCab.FYLKE));
        tCab.FYLKE = v;
    end
end

% Base are variables to be kept constant.
Ibr = zeros(size(tRes.Properties.VariableNames));
for i=1:length(base)
    If = ismember(tRes.Properties.VariableNames,base(i));
    Ibr = Ibr|If;
end
Ibc = zeros(size(tCab.Properties.VariableNames));
for i=1:length(base)
    If = ismember(tCab.Properties.VariableNames,base(i));
    Ibc = Ibc|If;
end
% Special fields are variables to be added.
Isr = contains(tRes.Properties.VariableNames,{'EmH'});
Isc = contains(tCab.Properties.VariableNames,{'EmH'});

% Remaining are Additave fields that will to be added.
Iar = ~Ibr&~Isr;
Iac = ~Ibc&~Isc;

% Make a very (unccesarily???) heavy merge of two tables. Dealing with
% variable sizes and properties on the parameters.
tOut  = table; tNow  = table;
ttemp = table; t2emp = table;

% Neewd 
fuID = unique([tRes.SSBID; tCab.SSBID]);
fprintf('Found %i unique fields\n',length(fuID))
% make a parsing function to deal with smaller tables.

Parssect = 20;

pars = ceil(length(fuID)/Parssect);
ts = now;
ruID= [];
fprintf('Go get a cup of coffee, this will take some time\n...\n')

for p = 1 : Parssect
    fprintf('Parse %i / %i @',p,Parssect)
    % split the unique ids into sections.
    if p == 1
        uID = fuID(1:pars);
    elseif p == Parssect
        uID = fuID(pars*(p-1)+1:end);
    else
        uID = fuID(pars*(p-1)+1:pars*(p));
    end
    
    for i = 1:length(uID)
        idr = find(tRes.SSBID==uID(i));
        idc = find(tCab.SSBID==uID(i));
        if ~isempty(idr) && ~isempty(idc)

            % merge the two tables to align columns
            tNow = [tRes(idr,:);tCab(idc,:)];
            
            % add the additive columns
            ttemp = array2table(nansum(table2array(tNow(:,Iar)),1));
            ttemp.Properties.VariableNames = tNow.Properties.VariableNames(Iar);
            % Treat the special column
            t2emp = array2table((table2array(tNow(1,Isr))*tNow.GridConsumption(1)+table2array(tNow(2,Isr))*tNow.GridConsumption(2))/nansum(tNow.GridConsumption));
            t2emp.Properties.VariableNames = tNow.Properties.VariableNames(Isr);
            temp = [tNow(1,Ibr),ttemp,t2emp];
            
            tOut =[tOut;temp];

        else
            tOut =[tOut;tRes(idr,:);tCab(idc,:)];
        end
        if rem(i,1000)==0; fprintf('%3i%%,',floor(100*i/length(uID))); end
    end
    fprintf('100%%\n')
    ts2 = now;
    fprintf('%3.1f min\n',(ts2-ts)*(24*60))
end

% Make a very (unccesarily) heavy merge of two tables. Dealing with
% variable sizes and properties on the parameters.
% tOut  = table; tNow  = table;
% ttemp = table; t2emp = table;
% 
% 
% for i = 1:length(uID)
%     idr = find(tRes.SSBID==uID(i));
%     idc = find(tCab.SSBID==uID(i));
%     if ~isempty(idr) && ~isempty(idc)
%         % merge the two tables to align columns
%         tNow = [tRes(idr,:);tCab(idc,:)];
%         % add the additive columns
%         ttemp = array2table(nansum(table2array(tNow(:,Iar)),1));
%         ttemp.Properties.VariableNames = tNow.Properties.VariableNames(Iar);
% 
%         % Treat the special column
%         t2emp = array2table((table2array(tNow(1,Isr))*tNow.GridConsumption(1)+table2array(tNow(2,Isr))*tNow.GridConsumption(2))/nansum(tNow.GridConsumption));
%         t2emp.Properties.VariableNames = tNow.Properties.VariableNames(Isr);
% 
%         temp = [tNow(1,Ibr),ttemp,t2emp];
%                 
%         tOut =[tOut;temp];
%     else
%         tOut =[tOut;tRes(idr,:);tCab(idc,:)];
%     end
%     if rem(i,500)==0; fprintf('%i / %i\n',i,length(uID)); end
% end

% Structurize the output table
S = table2struct(tOut);
end

