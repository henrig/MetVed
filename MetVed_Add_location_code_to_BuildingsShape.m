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
function [Sout] = MetVed_Add_location_code_to_BuildingsShape(K,S)
%--------------------------------------------------------------------------
% Metved: Emissions from Residential Wood Combustion 
%--------------------------------------------------------------------------
% Explanation goes here: 
% Part of MetVed_v2: GeoProcess two shapefields of different resolution.
% Placing one or more variables from S to K based on GeoMatching.

% 1st  NILU: Jan 2018: Henrik Grythe
% rev: NILU: Jun 2020: Henrik Grythe 
%--------------------------------------------------------------------------
fields = fieldnames(K);
% Three distinct properties can be added
types = [{'KOMMUNENUM'},{'FYLKESNR'},{'NUTS_ID'}];
typeN = [{'NAVN'},{'NAVN'},{'NUTS_NAME'}];

% Select the correct field to assingn, based on field name list
fieldADD = [{'KommuneNR'},{'FylkesNR'},{'LandsdelsNR'}];
for i=1:length(types)
    n(i) = sum(ismember(fields,types(i)));
    if n(i)>0
        fprintf('Adding %s to Gridfile\n',char(fieldADD(i)))
        ffield = types(i);
    end
end
t = find(n);

% If it does not find a field in the list, returns.
if isempty(t)
    fprintf('No Valid field in Geo File for processing \n')
    disp(fields)
    return
end


NR   = extractfield(K,char(types(t)));
NAME = extractfield(K,char(typeN(t)));


if iscell(NR)
    NR = regexprep(NR,'NO','');
    NR = str2num(char(NR));
end


% Create midpoint if needed
Ftype = S(1).Geometry;
fprintf('Geometry found for houses = %s\n',Ftype)
if ~ismember(Ftype,{'Point'})
    fprintf('Calculating Small-Grid (S) center by: (meanX meanY) \n')
    try
        for i= 1:length(S)
            x(i) = nanmean(extractfield(S(i),'X'));
            y(i) = nanmean(extractfield(S(i),'Y'));
        end
    catch
        for i= 1:length(S)
            x(i) = nanmean(extractfield(S(i),'x'));
            y(i) = nanmean(extractfield(S(i),'y'));
        end
    end
else
    try
        x = extractfield(S,'X');
        y = extractfield(S,'Y');
    catch
        x = extractfield(S,'x');
        y = extractfield(S,'y');
        
    end
end
% Create Table of the small Grid variable. 
T         = struct2table(S);

% Find Geography for all Grids with center in a municipality
Geography = zeros(size(S));
for i = 1:length(K)
    in = inpolygon(x,y,K(i).X,K(i).Y);
    Geography(in) = NR(i);
    fprintf('%03i Geography assigned NumGrids: %5i GEO: %i_%s \n',i,sum(in),NR(i),char(NAME(i)))
end

% Place municipalities for those that do not have midpoint in a municipality
nk = find(Geography==0);
fprintf('Unassigned Small-Grids by Center %i\n',length(nk))

if t ==3 && isfield(S,'FylkesNR')
    % This works for pre 2019 FylkesNr
    tk = zeros(size(nk));
    fnum = extractfield(S(nk),'FylkesNR');    
    o = find(fnum==3|fnum==2);
    tk(o) = 1;
    o = find(fnum==4|fnum==5);
    tk(o) = 2;
    o = find(fnum==1|fnum==6|fnum==7|fnum==8);
    tk(o) = 3;
    o = find(fnum==1|fnum==6|fnum==7|fnum==8);
    tk(o) = 3;
    o = find(fnum==9|fnum==10|fnum==11);
    tk(o) = 4;
    o = find(fnum==12|fnum==14|fnum==15);
    tk(o) = 5;   
    o = find(fnum==16|fnum==17);
    tk(o) = 6;
    o = find(fnum==19|fnum==20|fnum==18);
    tk(o) = 7;
    Geography(nk) = tk;
    nk = find(Geography==0);
    fprintf('Unassigned Small-Grids by FylkesNr %i\n',length(nk))
end


tk = zeros(size(nk));
% For each field try the corners:
if ~isempty(tk)
    for i = 1:length(K)
        for j= 1:length(nk)
            xc = extractfield(S(nk(j)),'X');
            yc = extractfield(S(nk(j)),'Y');
            for n = 1:4 % try each corner
                in = inpolygon(xc(n),yc(n),K(i).X,K(i).Y);
                if in
                    tk(j) =NR(i);
                end
            end
        end
    end
    Geography(nk) = tk;
    nk = find(Geography==0);
    fprintf('Unassigned Small-Grids by Corners %i\n',length(nk))
else
    fprintf('All Fields Assigned \n')
end
nk = find(Geography==0);
fprintf('Unassigned by midpoint %i\n',length(nk))




T.OldName = Geography;
idx       = find(ismember(T.Properties.VariableNames,{'OldName'}));
fprintf('Added field to Struct:\n%s\n****\n',char(fieldADD(t)))
T.Properties.VariableNames(idx) = fieldADD(t);
Sout      = table2struct(T);
end

