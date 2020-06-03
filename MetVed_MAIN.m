% 
fprintf('In MetVed_MAIN\n\n')
% add needed global fields
global ifiles

% MAIN
MetVed_check_Input()

[EFdata] = MetVed_Import_SSB_Consumption_and_EF();

% Need input from data 
out = MetVed_GeoProcess_Buildings(Res/Cab);




% MetCab Stuff v
%--------------------------------------------------------------------------
% Part 2 Calculate consumption 
%--------------------------------------------------------------------------
% Get emission factors (per Landsdel):

% Get total Cabins per fylke
for f=1:length(fnum)
    in                 = extractfield(Shy,'FYLKE')==fnum(f);
    Tot_Cab(1,fnum(f)) = nansum(extractfield(Shy(in),'bui2hol'))+nansum(extractfield(Shy(in),'bui2hut'));
    Tot_Cab(2,fnum(f)) = nansum(extractfield(Shy(in),'bui2hut'));
    Tot_Cab(3,fnum(f)) = nansum(extractfield(Shy(in),'bui2hol'));
end

%--------------------------------------------------------------------------
% In here would go some part to assign differentiated consumption weights. 
%--------------------------------------------------------------------------

% Use total Cabins per Landsdel to calculate consumption per hytte
[Hy, ~, HyT]   = xlsread(EFfile,'Landsdel_To_Fylke');
LDstr          = HyT(2:end,1);
for LD=1:7
    Fkes       = Hy(LD,~isnan(Hy(LD,:)));
    Fylker     = Fkes(2:end);
    L_Ncab(LD) = nansum(Tot_Cab(1,Fylker));
end
% Cons: Landsdel: 7   Tech   :  4    year: 12
% Cons: Landsdel: 7   SPECIES: 13    year: 12
yn = find(y==yyyy);
T_Cons = squeeze(Cons(:,1,find(y==yyyy)));
LEF    = squeeze(EF(:,:,find(y==yyyy)));
% Consumption Per HYtte and convert do dry wood consumption only
cphy   = 1e6*DryWoodFactor*T_Cons./L_Ncab';
% Emission per hytte (UNIT= consumption [kg] * EmissonFactor [g/kg''])
% ''Units vary for emission factors, look to emission factor input file.
Ephy   = cphy.*LEF;

% Parameter to split up the file into smaller managable pieces (to speed up)
part   = round(linspace(1,length(Shy),500));

% Snew Empty container for the cabins
Snew   = [];

[Ly, ~, LyT]    = xlsread(EFfile,'Fylke_To_Landsdel');

% Loop through the parts
for p=2:length(part)
    
    % the last part needs to be dealt with separately.
    if p<length(part)
        S=Shy(part(p-1):part(p)-1);
    else
        S=Shy(part(p-1):part(p));
    end
    % Calculate emissions and assign EMISSION fields to struct.
    for i=1:length(S)
        NK =  nansum(extractfield(S(i),'bui2hol'))+nansum(extractfield(S(i),'bui2hut'));
        f  = extractfield(S(i),'FYLKE');
        LD = Ly((Ly(:,1)==f),3);
        EM = squeeze(Ephy(LD,:))*NK;
        S  = setfield(S,{i},'Cons_kg',{1},cphy(LD)*NK); % Make a consumption field
        % Loop over all species.
        for j=1:size(SPEC,1)
            S = setfield(S,{i},sprintf('%s_%i',char(SPEC(j)),yyyy),{1},EM(j));
        end
        %if rem(i,500)==0; disp(i); end
    end
    part(p)
    Snew = cat(1,Snew,S);
end

% File of Hytter with kommune and fylkes ID
fname     = sprintf('%sCabin_Emissions_%04i',pname,yyyy);
dbfspec   = makedbfspec(Snew);
shapewrite(Snew, fname, 'DbfSpec', dbfspec)
pfilename = strcat(fname,'.prj');
fid       = fopen(pfilename,'w+');
fprintf(fid,'%s',prj);
fclose(fid);
fprintf('Wrote file  %s \n',fname)

[CHy, ~, CHyT]  = xlsread(EFfile,'9704-3');
LC              = CHy(2:4:end,:);
yr              = CHy(1,:);
Landsdel        = HyT(2:end,1);


for i=1:length(Landsdel)
    fprintf('%18s : %04i Consumption per Cabin %5.1f (N:%6i) \n',char(Landsdel(i)),yyyy,cphy(i),L_Ncab(i))
end

