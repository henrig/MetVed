function [S] = MetVed_Calculate_Residential_Emissions()
%--------------------------------------------------------------------------
% Metved: Emissions from Residential Wood Combustion 
%--------------------------------------------------------------------------
% Explanation goes here: 
% 
% NILU: Jan 2018: Henrik Grythe 
%--------------------------------------------------------------------------
global EFdata Res 

% unit conversion
KGtoTON =1e-3;
GtoTON  =1e-6;

% Load the shape 
S = Res;

% Extract the consumption field
if isfield(S,param)
    C = extractfield(S,param);
else
    error(sprintf('Missing field %s  in  KOMMUNE CONSUMPTION: \n %s \n',param,fname))
end


ks    = sprintf('%04i',KmneNr);
%ks=sprintf('%04i',KmneNr(1));
% param='WC_WE'

Fylke   = str2num(ks(1:2));
fy      = find(FylkeNr == Fylke);
Iy      = find(y==yyyy);
% Claulate emissions
for i=1:size(EF,2)
    EM(:,i)=C'*EF(fy,i,Iy);
end
% disp(fy)

fprintf('fylkeenummer / position     : %i / %i   \n',Fylke,fy) 
fprintf('%04i Tons of Wood Conusmed  : %5.0f       \n',KmneNr,sum(C)*1e-3)
fprintf('%04i Tons of PM2.5 Emissions: %6.2f       \n',KmneNr,sum(EM(:,1))*1e-6)
fprintf('%04i Emission Factor        : %6.2f === %6.2f \n',KmneNr,sum(EM(:,1))/sum(C),EF(fy,1,Iy))


% Assingn fields
for i=1:length(C)
    for j=1:size(SPEC,1)
    S = setfield(S,{i},sprintf('%s_%i',char(SPEC(j)),yyyy),{1},EM(i,j));
    end
end

Tk = nansum(EM*1e-6,1);
end
    

