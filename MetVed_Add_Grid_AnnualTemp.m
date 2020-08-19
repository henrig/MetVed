function [Sout] = MetVed_Add_Grid_AnnualTemp(S,T)
% MetVed_Add_Grid_Elevation function calculates an approximate elevation of
% each grid cell in a shape file of norway, by coupling it to an elevation
% file. The elevation is then added as a field in the snhapefile "MASL" -
% Metres Above Sea Level.
% Function assumes equal projection.
%--------------------------------------------------------------------------
% S = Input shape of GRID
% T = Topografic reference file


% Sfile ='/storage/nilu/Inby/Emission_Group/Emission_Models/MetVed/MetVed_v2/Input/Shapefiles/SSB/2015/SSB_2015_250m_Dwelling';
% S = shaperead(Sfile);
% 
% T = shaperead(Tfile);
tfields = fieldnames(T);
Ftype  = S(1).Geometry;
Ftype2 = T(1).Geometry;

fprintf('Geometry found for houses = %s\n',Ftype)
if ~ismember(Ftype,{'Point'})
    fprintf('Calculating Building Grid center (meanX meanY) \n')
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

fprintf('Geometry found for temperature = %s\n',Ftype2)
if ~ismember(Ftype2,{'Point'})
    fprintf('Calculating Temperature Grid center (meanX meanY) \n')
    try
        for i= 1:length(T)
            xt(i) = nanmean(extractfield(T(i),'X'));
            yt(i) = nanmean(extractfield(T(i),'Y'));
        end
    catch
        for i= 1:length(T)
            xt(i) = nanmean(extractfield(T(i),'x'));
            yt(i) = nanmean(extractfield(T(i),'y'));
        end
    end
else
    try
        xt = extractfield(T,'X');
        yt = extractfield(T,'Y');
    catch
        xt = extractfield(T,'x');
        yt = extractfield(T,'y');
    end
end


Ftype = T(1).Geometry;
fprintf('Geometry found for Temperature = %s\n',Ftype)

if  ismember(Ftype,{'Polygon'}) && ~isempty(find(ismember(tfields,'t2m')))
    fprintf('\t * Recognized Temperature file 0.1x0.1 degree Grid \n')
    t2m(1:length(x)) = NaN;
    for i = 1:length(T)
        in = inpolygon(x,y,T(i).X,T(i).Y);
        if sum(in)>0
            t2m(in) = T(i).t2m;
        end
        if rem(i,1000)==0; fprintf('Processed: %8i of %i  \n',i, length(T)); end
    end
    nk = find(isnan(t2m)); 
    fprintf('Unassigned Small-Grids  %i\n',length(nk))
    
    if ~isempty(nk)
        for i =1 :length(nk)
         dst = sqrt((x(nk(i))-xt).^2 + (y(nk(i))-yt).^2);
         idx = find(dst ==(min(dst)));
         t2m(nk(i)) = T(idx).t2m;
        end
        nk = find(isnan(t2m)); 
        fprintf('Unassigned Small-Grids  %i\n',length(nk))
    end
    st = struct2table(S);
    st.t2m = t2m';
    S = table2struct(st);
   
end

Sout = S;
end