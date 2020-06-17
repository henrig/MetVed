function MetVed_extract_dwelling_dependencies()
%--------------------------------------------------------------------------
% Metved: Emissions from Residential Wood Combustion 
%--------------------------------------------------------------------------
% Explanation goes here: 
% 
% NILU: Jan 2018: Henrik Grythe 
%--------------------------------------------------------------------------

global OvenDensity HouseEnergy HouseSizes text_div
global fp ec CF 

fprintf('\n%s\n',text_div)
fprintf('In MetVed_extract_dwelling_dependencies\n\n')

FylkePrct = shaperead(OvenDensity);
fprintf('Read file: %s\n',OvenDensity)
fp.fn     = str2num(char(extractfield(FylkePrct,'FYLKESNR')))';
fp.TWO    = extractfield(FylkePrct,'nCRAWLER_P_2'); nh.TWO=extractfield(FylkePrct,'nCRAWLER_TB');
fp.ROW    = extractfield(FylkePrct,'nCRAWLER_P_3'); nh.ROW=extractfield(FylkePrct,'nCRAWLER_RH');
fp.APA    = extractfield(FylkePrct,'nCRAWLER_P_');  nh.APA=extractfield(FylkePrct,'nCRAWLER_TB');
fp.ENE    = extractfield(FylkePrct,'nCRAWLER_P_1'); nh.ENE=extractfield(FylkePrct,'nCRAWLER_EB');

nh.TOT   = nh.TWO+nh.ROW+nh.ENE;
% Here we do a small correction on the webcrawling data, to make sure that
% we do not get a too low single house woodburning fraction and too low
% total number of devices.
fp.ENE   = (nh.TOT*0.82 -(nh.TWO.*fp.TWO +nh.ROW.*fp.ROW))./nh.ENE;

%-------------------------------------------------------------------------- %
% READ IN ENOVA STATISTICS FILE: it has categories for fylke and
% dwelling type.
[a,~,~]        = xlsread(HouseEnergy,'CleanCut');

T = readtable(HouseEnergy,'Sheet','CleanCut');
fprintf('Read file: %s\n',HouseEnergy)

FylkeHouseSize = shaperead(HouseSizes);
fprintf('Read file: %s\n',HouseSizes)

tfn = str2double(extractfield(FylkeHouseSize,'FYLKESNR'));

for i=1:height(T)
    I=find(tfn==T.FylkesNr(i));
    ec(i).eb = T.x0(i)+T.x1(i)*FylkeHouseSize(I).size_eb;
    ec(i).tb = T.x0(i)+T.x1(i)*FylkeHouseSize(I).size_tb;
    ec(i).rh = T.x0(i)+T.x1(i)*FylkeHouseSize(I).size_rh;
    ec(i).ap = T.x0_1(i)+T.x1_1(i)*FylkeHouseSize(I).size_ap;
    CF(i,1)  = ec(i).eb/ec(i).eb;
    CF(i,2)  = ec(i).tb/ec(i).eb;
    CF(i,3)  = ec(i).rh/ec(i).eb;
    CF(i,4)  = ec(i).ap/ec(i).eb;
end

% 
% for i=1:length(a)
%     I=tfn==a(i,1);
%     ec_eb(i) = a(i,4)+a(i,3)*FylkeHouseSize(I).size_eb;
%     ec_tb(i) = a(i,4)+a(i,3)*FylkeHouseSize(I).size_tb;
%     ec_rh(i) = a(i,4)+a(i,3)*FylkeHouseSize(I).size_rh;
%     ec_ap(i) = a(i,6)+a(i,5)*FylkeHouseSize(I).size_ap;
%     CF(i,1)  = ec_eb(i)/ec_eb(i);
%     CF(i,2)  = ec_tb(i)/ec_eb(i);
%     CF(i,3)  = ec_rh(i)/ec_eb(i);
%     CF(i,4)  = ec_ap(i)/ec_eb(i);
% end

end