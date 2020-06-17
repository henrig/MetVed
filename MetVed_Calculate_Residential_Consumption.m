function [] = MetVed_Calculate_Residential_Consumption()
%--------------------------------------------------------------------------
% Metved: Emissions from Residential Wood Combustion
%--------------------------------------------------------------------------
% Explanation goes here:
%
% NILU: Jan 2018: Henrik Grythe
%--------------------------------------------------------------------------

global DryWoodFactor Emission_year Ratio text_div EFdata Res
global fp CF

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

%--------------------------------------------------------------------------
% 1st: Loop Fylker to extract Fylke -level statistics
%--------------------------------------------------------------------------
% get fp_ variables 
global fp ec CF Primary

MetVed_extract_dwelling_dependencies()


% get ALL variable
ALL =[extractfield(Res,'dwe_det');extractfield(Res,'dwe_2dw');extractfield(Res,'dwe_row');extractfield(Res,'dwe_mult')]';


for i=1:length(FylkeNr)
    If  = extractfield(Res,'FylkesNR')==FylkeNr(i);
    Ify = fp.fn==(FylkeNr(i));
    
    % Precetage of units that are primary heating mechanisms
    pctPrim(i)    = 1+(Ratio*sum(([fp.ENE(Ify),fp.TWO(Ify),fp.ROW(Ify),fp.APA(Ify)].*nansum(ALL(If,:)).*Primary))/...
        sum([fp.ENE(Ify),fp.TWO(Ify),fp.ROW(Ify),fp.APA(Ify)].*nansum(ALL(If,:))));
    
    % Precetage of fireplaces that are primary heating mechanisms
    HpctPrim(i,:) = 1+Ratio*((([fp.ENE(Ify),fp.TWO(Ify),fp.ROW(Ify),fp.APA(Ify)].*nansum(ALL(If,:)).*Primary))/...
        sum([fp.ENE(Ify),fp.TWO(Ify),fp.ROW(Ify),fp.APA(Ify)].*nansum(ALL(If,:))));
    
    % Calculate the number of consumption units per fylke (N_CU_F)
    % Here are four alternative methods for calculation offered.
    N_CU_F(i,1)   = nansum(nansum(ALL(If,:)));                                      % Consumption Unit: 1 per Residential dwelling
    N_CU_F(i,2)   = (fp.APA(Ify)*nansum(ALL(If,4)) + fp.ROW(Ify)*nansum(ALL(If,3))...
        + fp.TWO(Ify)*nansum(ALL(If,2))  + fp.ENE(Ify)*nansum(ALL(If,1)));  % Consumption Unit: 1 per Chimney
    N_CU_F(i,3)   = N_CU_F(i,2)*pctPrim(i);                                 % Consumption Unit: 1 = Corrected N average consumption based on primary / supplementary !! Need a housing type correction factor.
    N_CU_F(i,4)   = sum([fp.ENE(Ify),fp.TWO(Ify),fp.ROW(Ify),fp.APA(Ify)].*nansum(ALL(If,:)).*HpctPrim(i,:).*CF(i,:)); %Consumption Unit: 1 = weighted units consumption for energy use RWC.
    % Consumption per Consumption unit. (kg)
    CpCU_F(i,1:4) = 1e6*Consumption(i)./N_CU_F(i,1:4);
    
end
% save(sprintf('Number_of_Houses_with_FP_in_%04i.mat',yyyy),'N_CU_F','CpCU_F','CF','Consumption')

%--------------------------------------------------------------------------
% 2nd Loop Kommuner to extract Kommune -level statistics
%--------------------------------------------------------------------------
for i=1:length(Kommuner)
    Ik=ALL(:,2)==Kommuner(i);
    Ify=fn==unique(ALL(Ik,1));
    Fpos=find(Fylker==unique(ALL(Ik,1)));
    
    % Precetage of fireplaces that are used as primary heating
    pctPrim(i)    = 1+(Ratio*sum(([fp_ENE(Ify),fp_TWO(Ify),fp_ROW(Ify),fp_APA(Ify)].*nansum(ALL(Ik,4:7)).*Primary))/...
        sum([fp_ENE(Ify),fp_TWO(Ify),fp_ROW(Ify),fp_APA(Ify)].*nansum(ALL(Ik,4:7))));
    
    % Precetage of fireplaces that are used as primary heating
    HpctPrim(i,:) = 1+Ratio*((([fp_ENE(Ify),fp_TWO(Ify),fp_ROW(Ify),fp_APA(Ify)].*nansum(ALL(Ik,4:7)).*Primary))/...
        sum([fp_ENE(Ify),fp_TWO(Ify),fp_ROW(Ify),fp_APA(Ify)].*nansum(ALL(Ik,4:7))));
    
    % Here the four alternative methods for calculation calculates accordingly.
    N_CU_K(i,1)  = nansum(ALL(ALL(:,2)==Kommuner(i),3));
    N_CU_K(i,2)  = (fp_APA(Ify)*nansum(ALL(Ik,7)) + fp_ROW(Ify)*nansum(ALL(Ik,6))  + fp_TWO(Ify)*nansum(ALL(Ik,5))  + fp_ENE(Ify)*nansum(ALL(Ik,4)));
    N_CU_K(i,3)  = N_CU_K(i,2)*pctPrim(i);
    N_CU_K(i,4)  = sum([fp_ENE(Ify),fp_TWO(Ify),fp_ROW(Ify),fp_APA(Ify)].*nansum(ALL(Ik,4:7)).*HpctPrim(i,:).*CF(Fpos,:));
    
    % Kommune Consumption using the four scenarios
    KC(i,1:4)    = CpCU_F(Fpos,1:4).*N_CU_K(i,1:4);
    
    % Difference in consumption between the scenarios
    Pdiff(i,:)   = 100*(KC(i,2:4)-KC(i,1))/KC(i,1);
    
    % Stats variabel for data analysis
    M(i,:)=[Kommuner(i),round(N_CU_K(i,:)),round(KC(i,:)),Pdiff(i,:)];
end
save(sprintf('Number_of_Houses_with_FP_in_%04i.mat',yyyy),'N_CU_F','N_CU_K','CpCU_F','CF','Consumption')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3rd: Within each Kommune: make a gridded distribution
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i=1:length(Kommuner)
    fname       = strcat(ipath,sprintf('%04i_%s_2015_SSB_dwelling',KmneNr(i),char(KmneNavn(i))));
    ofname      = sprintf('%sRWC_%04i/%04i_%s_%04i_RWC_Emissions_250UTM33',opath,yyyy,KmneNr(i),char(KmneNavn(i)),yyyy);
    Ik          = ALL(:,2) == Kommuner(i);
    Ify         = fn == unique(ALL(Ik,1));
    Fpos        = find(Fylker == unique(ALL(Ik,1)));
    
    Kdwe        = ALL(Ik,4:7);
    % Number of consumption units in each 250m grid
    N_CU_G(:,1) = nansum(Kdwe,2);
    N_CU_G(:,2) = nansum([fp_ENE(Ify)*Kdwe(:,1),fp_TWO(Ify)*Kdwe(:,2),fp_ROW(Ify)*Kdwe(:,3),fp_APA(Ify)*Kdwe(:,4)],2);
    N_CU_G(:,3) = N_CU_G(:,2)*pctPrim(i);
    N_CU_G(:,4) = nansum([fp_ENE(Ify)*Kdwe(:,1)*HpctPrim(i,1).*CF(Fpos,1),fp_TWO(Ify)*Kdwe(:,2)*HpctPrim(i,2).*CF(Fpos,2),...
        fp_ROW(Ify)*Kdwe(:,3)*HpctPrim(i,3).*CF(Fpos,3),fp_APA(Ify)*Kdwe(:,4)*HpctPrim(i,4).*CF(Fpos,4)]    ,2);

    % Calculate Grid Consumption using the four scenarios
    GC(:,1)     = CpCU_F(Fpos,1).*N_CU_G(:,1);
    GC(:,2)     = CpCU_F(Fpos,2).*N_CU_G(:,2);
    GC(:,3)     = CpCU_F(Fpos,3).*N_CU_G(:,3);
    GC(:,4)     = CpCU_F(Fpos,4).*N_CU_G(:,4);

    % Extract the necessesary fields.
    Kshape      = p250(Ik);
    

    % Number of dwellings with FirePlaces assumed in grid.
    % Wood Consumption in grid (based on FirePlaces).
    for g=1:length(Kshape)
        Kshape= setfield(Kshape,{g},'NFP'  ,{1},N_CU_G(g,2));
        Kshape= setfield(Kshape,{g},'WC_WE',{1},GC(g,4));

        % Also write the upper level consumption fraction.  
%         if Kshape(g).dwe_mult>0
%             APA_share = Kshape(i).dwe_mult/( Kshape(i).dwe_det+Kshape(i).dwe_2dw + Kshape(i).dwe_row + Kshape(i).dwe_mult);
%             Kshape    = setfield(Kshape,{g},'LLF'  ,{1}, 1-APA_share);
%             Kshape    = setfield(Kshape,{g},'ULF'  ,{1},APA_share);
%         else
%             Kshape    = setfield(Kshape,{g},'LLF'  ,{1}, 1);
%             Kshape    = setfield(Kshape,{g},'ULF'  ,{1},0);
%         end
%         
%         % The three disused consumption calculation methods.
%         Kshape= setfield(Kshape,{g},'WC_DN',{1},GC(g,1));
%         Kshape= setfield(Kshape,{g},'WC_FP',{1},GC(g,2));
%         Kshape= setfield(Kshape,{g},'WC_PS',{1},GC(g,3));
    end
    
    if re_write_consumption  % Will overwrite existing files
        dbfspec=makedbfspec(Kshape);
        shapewrite(Kshape, ofname, 'DbfSpec', dbfspec)
        pfilename=strcat(ofname,'.prj');
        fid=fopen(pfilename,'w+');
        fprintf(fid,'%s',prj);
        fclose(fid);
    end
    % Calculate emissions in each grid, based on consumption
    if re_calc_emissions    % calculate emissions from a file given consumption
        [Tk(i,:), Kshape] = MetVed_Calculate_Wood_Emissions(Kshape,fname,KmneNr(i),'WC_WE',yyyy);
    end
    
    if re_write_emission  % Overwrite existing files
        dbfspec=makedbfspec(Kshape);
        shapewrite(Kshape, ofname, 'DbfSpec', dbfspec)
        pfilename=strcat(ofname,'.prj');
        fid=fopen(pfilename,'w+');
        fprintf(fid,'%s',prj);
        fclose(fid);
    end
    fprintf('%04i_%s_%04i_RWC_Emissions \n',KmneNr(i),char(KmneNavn(i)),yyyy)
    clear Kshape N_CU_G GC
end


end