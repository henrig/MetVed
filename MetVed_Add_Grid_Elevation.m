function [Sout] = MetVed_Add_Grid_Elevation(S,T)
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
% Tfile = '/storage/nilu/Inby/Emission_Group/Ancillary_Data/ShapeFiles/Topo/NO_topo_points';
% Tfile = '/storage/nilu/Inby/Emission_Group/Ancillary_Data/ShapeFiles/Topo/NO_topo_lines';
% Tfile = '/storage/nilu/Inby/Emission_Group/Ancillary_Data/ShapeFiles/Topo/NO_topo_area';
% T = shaperead(Tfile);
tfields = fieldnames(T);
Ftype = S(1).Geometry;
fprintf('Geometry found for houses = %s\n',Ftype)
if ~ismember(Ftype,{'Point'})
    fprintf('Calculating Grid center (meanX meanY) \n')
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

Ftype = T(1).Geometry;
fprintf('Geometry found for Topography = %s\n',Ftype)
hoyde = extractfield(T,'hoyde');
if ismember(Ftype,{'Point'})
    try
        xt = extractfield(T,'X');
        yt = extractfield(T,'Y');
    catch
        xt = extractfield(T,'x');
        yt = extractfield(T,'y');
    end
    fprintf('Assigning elevation by nearest point \n')
    for i = 1:size(x,2)
        dst = sqrt((x(i)-xt).^2 + (y(i)-yt).^2);
        ele = find(dst==min(dst));
        MASL(i) = hoyde(ele);
        S(i).MASL = hoyde(ele);
    end
end
if ismember(Ftype,{'Line'})
    % hoyder = extractfield(T,'hoyde');
    % unique(hoyder)
    
    try
        for i= 1:length(T)
            xt(i) = nanmean(extractfield(T(i),'X'));
            yt(i) = nanmean(extractfield(T(i),'Y'));
        end
    catch
        for i= 1:length(S)
            xt(i) = nanmean(extractfield(T(i),'x'));
            yt(i) = nanmean(extractfield(T(i),'y'));
        end
    end
    % This is a double simplification both midpoints and midpoints are
    % used. This is perhaps an oversimplifiaction, so added som more detail
    % to be calculated for nearby iso-lines.
    fprintf('Tier1 : Closest centerpoint i can find (distant iso-lines flat)\n')
    fprintf('Tier2 : Closest centerpoint i can find (details of nearby iso-lines)\n')
    fprintf('Tier3 : Average of iso-lines in grid   (as exact as possible)\n')
    k = zeros(size(S));
    for i = 1:size(x,2)
        dst  = sqrt((x(i)-xt).^2 + (y(i)-yt).^2);
        ele = find(dst<10000);
        if isempty(ele)% Tier1
            ele  = find(dst==min(dst));
            S(i).MASL = hoyde(ele);
            k(i) = 1;
        else
            xf = extractfield(T(ele),'X');
            yf = extractfield(T(ele),'Y');
            in = inpolygon(xf,yf,S(i).X,S(i).Y);
            if sum(in)==0% Tier2
                dst  = sqrt((x(i)-xf).^2 + (y(i)-yf).^2);
                ele2  = find(dst==nanmin(dst));
                S(i).MASL = mean(hoyde(ele2));
                k(i) = 2;
            else%% Tier3
                inan = cumsum(isnan(xf));
                for j=1:length(unique(inan))-1
                    hoy(find(inan==j-1))= hoyde(ele(j));
                end
                S(i).MASL = mean(hoy(in));
                k(i) = 3;
            end
            %         MASL(i)   = hoyde(ele);
            %         S(i).MASL = hoyde(ele);
        end
        if rem(i,10000)==0; fprintf('Processed: %8i of %i Grids assigned: Tier1/2/3: %i / %i / %i \n',i, length(x),sum(k==1),sum(k==2),sum(k==3) ); end
    end
    
end

if ismember(Ftype,{'Polygon'}) && ~isempty(find(ismember(tfields,'minhoyde')))
    hoyder = extractfield(T,'minhoyde');
    unique(hoyder)
    idx = find(hoyder>0);
    MASL(1:length(x)) = 0;
    for i = 1:length(T)
        in = inpolygon(x,y,T(i).X,T(i).Y);
        if sum(in)>0
            MASL(in) = T(i).minhoyde;
        end
        if rem(i,1000)==0; fprintf('Processed: %8i of %i  \n',i, length(T)); end
    end
    st = struct2table(S);
    st.MASL = MASL';
    S = table2struct(st)
end

Sout = S;
end
% prj = 'PROJCS["SWEREF99_TM",GEOGCS["GCS_SWEREF99",DATUM["D_SWEREF99",SPHEROID["GRS_1980",6378137,298.257222101]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]],PROJECTION["Transverse_Mercator"],PARAMETER["latitude_of_origin",0],PARAMETER["central_meridian",15],PARAMETER["scale_factor",0.9996],PARAMETER["false_easting",500000],PARAMETER["false_northing",0],UNIT["Meter",1]]';
% dbf = makedbfspec(Sout);
% shapewrite(Sout,'Buildings_With_Elevation','DbfSpec',dbf)
% pfilename = strcat('Buildings_With_Elevation','.prj');
% fid       = fopen(pfilename,'w+');
% fprintf(fid,'%s',prj);
% fclose(fid);
%




