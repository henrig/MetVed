function Calendar = Cabin_population(date,Cabin_Population_file)
% PARAMETERIZATION :

% Daily Weight: time variation for norwegian traffic Norsk Regnesentral:
% Saturday Applied as sunday, Friday and Sunday applied as Saturday.
tt2      = 1./[0.27,0.07,0.05];
cabindag = tt2/sum(tt2);

Calendar = Find_Norwegian_Holidays(date,Cabin_Population_file);

Twe = readtable(Cabin_Population_file,'Sheet','TrafficVolume');
for i = 1:height(Calendar)
    if Calendar.Weeknum(i)>0
        weigh(i,1) = Twe.SummerWeek(Calendar.Weeknum(i))*cabindag(Calendar.Cabin_day(i))*Calendar.Summer_Factor(i);
        weigh(i,2) = Twe.WinterWeek(Calendar.Weeknum(i))*cabindag(Calendar.Cabin_day(i))*Calendar.Winter_Factor(i);
    else
        weigh(i,1) = Twe.SummerWeek(1)*cabindag(Calendar.Cabin_day(i))*Calendar.Summer_Factor(i);
        weigh(i,2) = Twe.WinterWeek(1)*cabindag(Calendar.Cabin_day(i))*Calendar.Winter_Factor(i);
    end
    
end

Calendar.PopWeight_Summer = weigh(:,1);
Calendar.PopWeight_Winter = weigh(:,2);
end
