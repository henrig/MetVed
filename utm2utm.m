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

