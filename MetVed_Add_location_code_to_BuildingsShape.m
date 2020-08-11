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

% 
fieldADD = [{'KommuneNR'},{'FylkesNR'},{'LandsdelsNR'}];
for i=1:length(types)
    n(i) = sum(ismember(fields,types(i)));
    if n(i)>0
        fprintf('Adding %s to Gridfile\n',char(fieldADD(i)))
    end
end
t = find(n);

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
    fprintf('Assigning Administrative unit by Grid center (meanX meanY) \n')
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

% Find Geography for all Grids with center in a municipality
Kommune = zeros(size(S));
for i = 1:length(K)
    in = inpolygon(x,y,K(i).X,K(i).Y);
    Kommune(in) = NR(i);
    fprintf('%03i Geography NumGrid: %5i GEO: %i_%s \n',i,sum(in),NR(i),char(NAME(i)))
end

% Place municipalities for those that do not have midpoint in a municipality
nk = find(Kommune==0);
fprintf('Unasigned %i\n',length(nk))
if ~ismember(Ftype,'Point')
    for i= 1:length(nk)
        xc = extractfield(S(nk(i)),'X');
        yc = extractfield(S(nk(i)),'Y');
        for j = 1:length(xc)
            in = inpolygon(xc(j),yc(j),K(i).X,K(i).Y);
            if ~isempty(in)
                tk(i,j) = K(i).KOMMUNENUM;
                fprintf('%03i Kommune NumGrid: %5i Kmne: %i_%s \n',i,sum(in),NR(i),char(NAME(i)))
            end
        end
    end
    Kommune(nk) = tk(:,1);
end
tk
nk = find(Kommune==0);
fprintf('Unassigned by midpoint %i\n',length(nk))

% Create and rename the variable. Then remake into a structure array.
T         = struct2table(S);
T.OldName = Kommune;
idx       = find(ismember(T.Properties.VariableNames,{'OldName'}));
fprintf('Added field to Struct:\n%s\n****\n',char(fieldADD(t)))
T.Properties.VariableNames(idx) = fieldADD(t);
Sout      = table2struct(T);
end

