function [] = write_MetVed_EPISODE_emissions_netCDFfile(ofname,TV,Compounds,ED,yyyy)
% Function to write a new EPISODE NetCDF emissions file.

% better found from elsewhere!
dx = 1000;
dy = 1000;

% Only works if grid is not twisted
Ax = extractfield(ED,'X');
Ay = extractfield(ED,'Y');
Ox = nanmin(Ax);
Oy = nanmin(Ay);
nX = round((nanmax(Ax)-nanmin(Ax)-dx)/(dx));
nY = round((nanmax(Ay)-nanmin(Ay)-dy)/(dy));

if nX*nY ~=length(ED)
    warning('DO NOT USE ROTATED GRIDS')
    warning('Overwriting values with test Values')
    ofname = sprintf('Test_EPISODE_netCDF_Emissions.nc',char(spec(sp)));
    Ox = 300671.0;
    Oy = 7055732.3;
    nX = 26;
    nY = 28;
end

nZ = 3; 
nT = length(TV); 

if exist(ofname)
    delete(ofname)
    fprintf('#### Deleted the existing file\n to make new\n %s\n\n',ofname)
end

% Create the 4 dimensions the  NetCDF file needs. x,y,z and time
nccreate(ofname,   'x', 'Dimensions',{ 'x', nX}, 'DataType', 'single');
ncwrite(ofname,    'x',  Ox:dx:Ox+(dx*(nX-1)) );
ncwriteatt(ofname, 'x', 'long_name', 'projection_x_coordinate');

nccreate(ofname,   'y', 'Dimensions',{ 'y', nY}, 'DataType', 'single');
ncwrite(ofname,    'y', Oy:dy:Oy+(dy*(nY-1)) );
ncwriteatt(ofname, 'y', 'long_name', 'projection_y_coordinate');

nccreate(ofname,   'z', 'Dimensions',{ 'z', nZ}, 'DataType', 'single');
ncwrite(ofname,    'z', 1:nZ );
ncwriteatt(ofname, 'z', 'long_name', 'projection_y_coordinate');

nccreate(ofname,  'time', 'Dimensions',{ 'time', nT}, 'DataType', 'single');
ncwrite(ofname,   'time', 1:nT);
ncwriteatt(ofname,'time', 'long_name', 'hour_starting' );


% wood specific parameter for TV 
Vname     = sprintf('%s','HW_RWC');
LVname    = sprintf('%s','Hourly_Weight_Residential_Wood_Combustion');
nccreate(ofname  , Vname, 'Dimensions', {'time', nT}, 'DataType', 'single');
ncwrite(ofname   , Vname, TV );
ncwriteatt(ofname, Vname, 'long_name',LVname);
ncwriteatt(ofname, Vname, 'units','hours');

% wood specific parameter for altitude
a = extractfield(ED,sprintf('LowFr_%i',yyyy));
var  = reshape(a,nX,nY);
Hvar = zeros(nX,nY,nZ);
Hvar(:,:,1) = var;
Hvar(:,:,2) = 1-var;
Vname     = sprintf('%s','Altitude_frac');
LVname    = sprintf('%s','Emission Altitude MetVed RWC emissions');
nccreate(ofname  , Vname, 'Dimensions', {'x', nX,'y', nY,'z', nZ}, 'DataType', 'single');
ncwrite(ofname   , Vname, Hvar );
ncwriteatt(ofname, Vname, 'long_name',LVname);
ncwriteatt(ofname, Vname, 'units','fractions');

% wood emissions for each compound
for i=1:size(Etot,1)
    a = extractfield(ED,sprintf('%s_%i',char(Compounds(i)),yyyy));
    Nvar  = reshape(a,nX,nY);
    Vname     = sprintf('%s_%s','Emis',char(Compounds(i)));
    LVname    = sprintf('%s_%s','gram_Emisssions_of_',char(Compounds(i)));
    nccreate(ofname  , Vname, 'Dimensions', {'i', nX,'j', nY}, 'DataType', 'single');
    ncwrite(ofname   , Vname, Nvar );
    ncwriteatt(ofname, Vname, 'long_name',LVname);
    ncwriteatt(ofname, Vname, 'units','gram/year');
end
% Fill file with some attributes:
ncwriteatt(ofname,'/','projection','UTM 33N');
ncwriteatt(ofname,'/','Grid_resolutionX',dx);
ncwriteatt(ofname,'/','Grid_resolutionY',dy);
ncwriteatt(ofname,'/','comment','MetVed Emissions file for EPISODE');
ncwriteatt(ofname,'/','created_date',datestr(now,'yyyy-mm-dd'));
ncwriteatt(ofname,'/','created_hour',datestr(now,'HHMMSS'));
ncwriteatt(ofname,'/','lastmodified_date',datestr(now,'yyyy-mm-dd'));
ncwriteatt(ofname,'/','lastmodified_hour',datestr(now,'HHMMSS'));
fprintf('......wrote NetCDF file: \n%s\n with dimensions:\n',ofname)
fprintf('nX: %4i dx: %4i \n',nX,dx)
fprintf('nY: %4i dy: %4i \n',nY,dy)
fprintf('nZ: %4i \n',nZ)
fprintf('Time: %4i (Year %i)\n\n\n\n',nT,yyyy)



end
