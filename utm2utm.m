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
function [S] = utm2utm(S,utmFrom,utmTo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EERT: Exhaust Emissions from Road Traffic 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Explanation goes here: 
% Small function to convert between utm coordinates. 

% Uses: utm2deg and wgs2utm

% NILU: Apr 2018: Henrik Grythe 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('X %8.1f  Y %8.1f UTM: %02i\n',S(1).X(1),S(1).Y(1),utmFrom)

for i=1:length(S)
    BB=S(i).BoundingBox;
    X=S(i).X;
    Y=S(i).Y;
    
    [Lat,Lon] = utm2deg(BB(:,1),BB(:,2),repmat(sprintf('%02i N',utmFrom),size(BB,1),1));
    [xbb,ybb,~,~]=wgs2utm(Lat,Lon,utmTo,'N');
    S(i).BoundingBox=[xbb,ybb];
    
    [Lat,Lon] = utm2deg(X,Y,repmat(sprintf('%02i N',utmFrom),size(X,2),1));
    [x,y,~,~]=wgs2utm(Lat,Lon,utmTo,'N');
    S(i).X=x;
    S(i).Y=y;
end

fprintf('X %8.1f  Y %8.1f UTM: %02i\n',S(1).X(1),S(1).Y(1),utmTo)


end

