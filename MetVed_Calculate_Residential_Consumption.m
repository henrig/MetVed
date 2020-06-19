function [] = MetVed_Calculate_Residential_Consumption()
%--------------------------------------------------------------------------
% Metved: Emissions from Residential Wood Combustion
%--------------------------------------------------------------------------
% Explanation goes here:
%
% NILU: Jan 2018: Henrik Grythe
%--------------------------------------------------------------------------

global DryWoodFactor Emission_year Ratio text_div EFdata Res
global fp ec CF Primary Emission_year

fprintf('\n%s\n',text_div)
fprintf('In MetVed_Calculate_Residential_Consumption\n\n')

% Extract the position of the year for EF and Consumption data:
Ey  = find(EFdata.res3D ==Emission_year);

Tfylke = table;

Tfylke.ResFylker = unique(extractfield(Res,'FylkesNR'))';
% Check that it matches the fylkes in the GeoFile:

% Extract the existing fylkes number in the file:
fprintf('Using dry Wood Factor of: %f \n',DryWoodFactor)
Cons1D = squeeze(EFdata.resCON(:,:,Ey))*DryWoodFactor;
EF1D   = array2table(squeeze(EFdata.resEF(:,:,Ey)')');
spec   = EFdata.res2D;
EF1D.Properties.VariableNames=spec;

FylkeNr    = EFdata.res1D;
FylkesNavn = EFdata.res1Dn;
SFylkeNr   = unique(extractfield(Res,'FylkesNR'));

% Write out no match Fylkes:
Tn =[];
for i =1: height(Tfylke)
    T = table;
    idx = find(FylkeNr == Tfylke.ResFylker(i));
    if ~isempty(idx)
        T.FylkeNavn(i) = FylkesNavn(idx);
        T.FylkeNr(i)   = FylkeNr(idx);
        T.ConsTot(i)   = Cons1D(idx,1);
        Tn = [Tn;[T(i,:),EF1D(idx,:)]];
    else
       fprintf('WARNING! No consumption for Fylke %i\n',Tfylke.ResFylker(i)) 
    end
end

MetVed_extract_dwelling_dependencies()

%--------------------------------------------------------------------------
% 1st: Loop Fylker to extract Fylke -level statistics
%--------------------------------------------------------------------------
% Create a variable ALL that includes all buildings part of the
% calculations.

ALL =[extractfield(Res,'dwe_det');extractfield(Res,'dwe_2dw');extractfield(Res,'dwe_row');extractfield(Res,'dwe_mult')]';
y = find(EFdata.res3D==Emission_year);
% WOOD POTENTIAL OF EACH BUILDING in the Fylke
WOODPOTENTIAL  = zeros(size(Res));
GridConsumption = zeros(size(Res));
Consumtion = table;
for i=1:length(FylkeNr)
    If  = find(extractfield(Res,'FylkesNR')==FylkeNr(i));
    Ifc = find(EFdata.res1D==FylkeNr(i));
    Ify = find(fp.fn==(FylkeNr(i)));
    fprintf('%s \n',char(FylkesNavn(i)))
    if isempty(If) || isempty(Ifc) ||  isempty(Ify)
        fprintf('Something went wrong for FylkeNr %i \n',FylkeNr(i))
        fprintf('\tFylkeNr %i , #HouseGrids: %i \n',FylkeNr(i),length(If))
        fprintf('\tFylkeNr %i , #EFdata: %i \n',FylkeNr(i),Ifc)
        fprintf('\tFylkeNr %i , #HouseSTats: %i \n',FylkeNr(i),Ify)
        fprintf('MISSING data\n%s\n',text_div)
    else       
        % Here we apply 3 correction factors for building type and for 
        % Multiplier = 1+fraction of fireplaces that are primary heating mechanisms
        Multiplier(i,:) = 1+ Ratio*((([fp.ENE(Ify),fp.TWO(Ify),fp.ROW(Ify),fp.APA(Ify)].*nansum(ALL(If,:)).*Primary))/...
            sum([fp.ENE(Ify),fp.TWO(Ify),fp.ROW(Ify),fp.APA(Ify)].*nansum(ALL(If,:))));
        
        % Calculate the number of consumption units per fylke (N_CU_F)
        Consumption.TotalUnits(i)   = sum([fp.ENE(Ify),fp.TWO(Ify),fp.ROW(Ify),fp.APA(Ify)].*nansum(ALL(If,:)).*Multiplier(i,:).*CF(i,:));        
        fprintf('Consumption Units : %i Units\n',round(Consumption.TotalUnits(i)))
        
        % Consumption per Consumption unit. (kg) per house type (1-4)
        Consumption.per_Unit(i) = 1e6*EFdata.resCON(Ifc,1,y)./Consumption.TotalUnits(i);
        fprintf('Consumption per Unit : %i kg\n',round(Consumption.per_Unit(i)))
        
        % GRIDDED WOOD POTENTIAL
        WOODPOTENTIAL(If) = nansum([fp.ENE(Ify)*ALL(If,1)*Multiplier(i,1).*CF(Ify,1),fp.TWO(Ify)*ALL(If,2)*Multiplier(i,2).*CF(Ify,2),...
        fp.ROW(Ify)*ALL(If,3)*Multiplier(i,3).*CF(Ify,3),fp.APA(Ify)*ALL(If,4)*Multiplier(i,4).*CF(Ify,4)],2);
    
        GridConsumption(If) =  WOODPOTENTIAL(If)*Consumption.per_Unit(i);
    
        fprintf('Dealt wood to FylkeNr %s: %i kg of : %4.1f Ton \n',char(FylkesNavn(i)),round(sum(GridConsumption(If))),EFdata.resCON(Ifc,1,y))
    end
end
fprintf('Adding WOODPOTENTIAL and Grid Consumption to shape...\n')
T = struct2table(Res);
T.WOODPOTENTIAL   = WOODPOTENTIAL;
T.GridConsumption = GridConsumption*DryWoodFactor;
Res = table2struct(T);
fprintf('Return\n')


% 
% 
% % 
% % Res.WOODPOTENTIAL = 
% 
% %EMISSION_pCU_F(i,1:4) = EFdata.resEF(:,1,y)./CpCU_F(i,1:4));
% 
% 
% 
% %save(sprintf('Number_of_Houses_with_FP_in_%04i.mat',yyyy),'N_CU_F','CpCU_F','CF','Consumption')
% 
% %--------------------------------------------------------------------------
% % 2nd Loop Kommuner to extract Kommune -level statistics
% %--------------------------------------------------------------------------
% KommuneNr = unique(extractfield(Res,'KommuneNR'))';
% 
% for i=1:length(KommuneNr)
%     Ik   = find(extractfield(Res,'KommuneNR')==KommuneNr(i));
%     Ify  = fp.fn       == unique(floor(KommuneNr(i)/100));
%     Fpos = find(FylkeNr == unique(extractfield(Res(Ik),'FylkesNR')));
%     
%     if isempty(If) || isempty(Ifc) ||  isempty(Ify)
%         fprintf('Something went wrong for FKommuneNr %i \n',KommuneNr(i))
%         fprintf('\tKommuneNr %i , #Houses: %i \n',KommuneNr(i),length(Ik))
%         fprintf('\tKommuneNr %i , #EFdata: %i \n',KommuneNr(i),Ifc)
%         fprintf('\tKommuneNr %i , #HouseSTats: %i \n',KommuneNr(i),Ify)
%         fprintf('MISSING data\n%s\n',text_div)
%     else
%         
%         % Precetage of fireplaces that are used as primary heating
%         pctPrim(i)    = 1+(Ratio*sum(([fp.ENE(Ify),fp.TWO(Ify),fp.ROW(Ify),fp.APA(Ify)].*nansum(ALL(Ik,:)).*Primary))/...
%             sum([fp.ENE(Ify),fp.TWO(Ify),fp.ROW(Ify),fp.APA(Ify)].*nansum(ALL(Ik,:))));
%         
%         % Precetage of fireplaces that are used as primary heating
%         HpctPrim(i,:) = 1+Ratio*((([fp.ENE(Ify),fp.TWO(Ify),fp.ROW(Ify),fp.APA(Ify)].*nansum(ALL(Ik,:)).*Primary))/...
%             sum([fp.ENE(Ify),fp.TWO(Ify),fp.ROW(Ify),fp.APA(Ify)].*nansum(ALL(Ik,:))));
%         
%         % Here the four alternative methods for calculation calculates accordingly.
%         N_CU_K(i,1)  = nansum(nansum(ALL(Ik,:)));;
%         N_CU_K(i,2)  = (fp.APA(Ify)*nansum(ALL(Ik,4)) + fp.ROW(Ify)*nansum(ALL(Ik,3))  + fp.TWO(Ify)*nansum(ALL(Ik,2))  + fp_ENE(Ify)*nansum(ALL(Ik,1)));
%         N_CU_K(i,3)  = N_CU_K(i,2)*pctPrim(i);
%         N_CU_K(i,4)  = sum([fp.ENE(Ify),fp_TWO(Ify),fp.ROW(Ify),fp.APA(Ify)].*nansum(ALL(Ik,:)).*HpctPrim(i,:).*CF(Fpos,:));
%         
%         % Kommune Consumption using the four scenarios
%         KC(i,1:4)    = CpCU_F(Fpos,1:4).*N_CU_K(i,1:4);
%         
%         % Difference in consumption between the scenarios
%         Pdiff(i,:)   = 100*(KC(i,2:4)-KC(i,1))/KC(i,1);
%         
%         % Stats variabel for data analysis
%         M(i,:)=[Kommuner(i),round(N_CU_K(i,:)),round(KC(i,:)),Pdiff(i,:)];
%     end
% end
% save(sprintf('Number_of_Houses_with_FP_in_%04i.mat',yyyy),'N_CU_F','N_CU_K','CpCU_F','CF','Consumption')
% 
% 
% %--------------------------------------------------------------------------
% % 3rd: GRID 
% %--------------------------------------------------------------------------
% for i=1:length(Kommuner)
%     fname       = strcat(ipath,sprintf('%04i_%s_2015_SSB_dwelling',KmneNr(i),char(KmneNavn(i))));
%     ofname      = sprintf('%sRWC_%04i/%04i_%s_%04i_RWC_Emissions_250UTM33',opath,yyyy,KmneNr(i),char(KmneNavn(i)),yyyy);
%     Ik          = ALL(:,2) == Kommuner(i);
%     Ify         = fn == unique(ALL(Ik,1));
%     Fpos        = find(Fylker == unique(ALL(Ik,1)));
%     
%     Kdwe        = ALL(Ik,4:7);
%     % Number of consumption units in each 250m grid
%     N_CU_G(:,1) = nansum(Kdwe,2);
%     N_CU_G(:,2) = nansum([fp_ENE(Ify)*Kdwe(:,1),fp_TWO(Ify)*Kdwe(:,2),fp_ROW(Ify)*Kdwe(:,3),fp_APA(Ify)*Kdwe(:,4)],2);
%     N_CU_G(:,3) = N_CU_G(:,2)*pctPrim(i);
%     N_CU_G(:,4) = nansum([fp_ENE(Ify)*Kdwe(:,1)*HpctPrim(i,1).*CF(Fpos,1),fp_TWO(Ify)*Kdwe(:,2)*HpctPrim(i,2).*CF(Fpos,2),...
%         fp_ROW(Ify)*Kdwe(:,3)*HpctPrim(i,3).*CF(Fpos,3),fp_APA(Ify)*Kdwe(:,4)*HpctPrim(i,4).*CF(Fpos,4)]    ,2);
% 
%     % Calculate Grid Consumption using the four scenarios
%     GC(:,1)     = CpCU_F(Fpos,1).*N_CU_G(:,1);
%     GC(:,2)     = CpCU_F(Fpos,2).*N_CU_G(:,2);
%     GC(:,3)     = CpCU_F(Fpos,3).*N_CU_G(:,3);
%     GC(:,4)     = CpCU_F(Fpos,4).*N_CU_G(:,4);
% 
%     % Extract the necessesary fields.
%     Kshape      = p250(Ik);
%     
% 
% %     % Number of dwellings with FirePlaces assumed in grid.
% %     % Wood Consumption in grid (based on FirePlaces).
% %     for g=1:length(Kshape)
% %         Kshape= setfield(Kshape,{g},'NFP'  ,{1},N_CU_G(g,2));
% %         Kshape= setfield(Kshape,{g},'WC_WE',{1},GC(g,4));
% % 
% %     end
% %     
% %     if re_write_consumption  % Will overwrite existing files
% %         dbfspec=makedbfspec(Kshape);
% %         shapewrite(Kshape, ofname, 'DbfSpec', dbfspec)
% %         pfilename=strcat(ofname,'.prj');
% %         fid=fopen(pfilename,'w+');
% %         fprintf(fid,'%s',prj);
% %         fclose(fid);
% %     end
% %     % Calculate emissions in each grid, based on consumption
% %     if re_calc_emissions    % calculate emissions from a file given consumption
% %         [Tk(i,:), Kshape] = MetVed_Calculate_Wood_Emissions(Kshape,fname,KmneNr(i),'WC_WE',yyyy);
% %     end
% %     
% %     if re_write_emission  % Overwrite existing files
% %         dbfspec=makedbfspec(Kshape);
% %         shapewrite(Kshape, ofname, 'DbfSpec', dbfspec)
% %         pfilename=strcat(ofname,'.prj');
% %         fid=fopen(pfilename,'w+');
% %         fprintf(fid,'%s',prj);
% %         fclose(fid);
% %     end
% %     fprintf('%04i_%s_%04i_RWC_Emissions \n',KmneNr(i),char(KmneNavn(i)),yyyy)
% %     clear Kshape N_CU_G GC
% % end


end