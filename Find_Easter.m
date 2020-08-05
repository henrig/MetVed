function ED = Find_Easter(date)
% This function computes the Date of Easter, using the Gauss algorithm.

dv = round(datevec(date));
Y  = dv(1);
P  = floor(Y./100);        % P is simply the century index
Q  = floor((3.*P+3)./4);   % Q takes care of the leap day difference between the Julian and the Gregorian calendar
R  = floor((8.*P+13)./25); % R handles the shift of the Metonic cycle
M  = floor(mod((15+Q-R),30));
N  = floor(mod((4+Q),7));
M(Y<=1582)=15;
N(Y<=1582)=6;
A = mod(Y,19);
C = mod(Y,7);
B = mod(Y,4);
D = mod((19 .* A + M),30);
E = mod(((2 .* B) + (4 .* C) + (6 .* D) + N),7);
F = (22 + D + E);
Em = 3.*ones(size(Y));
I=find(F>31);
if isempty(I)==0
    F(I)=F(I)-31;
    Em(I)=4;
    K=find((F(I)==26) | (F(I)==25 & E(I)==6 & A(I)>10));
    if isempty(K)==0
        F(I(K))=F(I(K))-7;
    end
end
%Transform the dates in Matlab format
ED = datenum(Y,Em,F);
end