function [TV,dnew] = MetVed_timevariation(HDDfile,Htres,utmTo,yyyy,dn,cpx,cpy)
%--------------------------------------------------------------------------
% Metved: Emissions from Residential Wood Combustion
%--------------------------------------------------------------------------
% Function to calculate the woodburning timevariation 
% takes a matlab dateformatted array (uses start and end) 
% and returns an Hourly emission function in the Hours in-between.
% Henrik Grythe -Dec.2017  -NILU, Kjeller
% Henrik Grythe -Aug.2020  -NILU, Kjeller
%--------------------------------------------------------------------------
stepOut=1/24;
dnew=min(dn):stepOut:max(dn)+1-stepOut;
% First calculate the HDD, should include if
% not working use secondary station.

% [St,~,StT]=xlsread(HDDfile,'Stations');
St = readtable(HDDfile,'Sheet','Stations');

% Transform to UTM coordinates
[x,y,~,~]   = wgs2utm(St.Latitude,St.Longitude,utmTo,'N');
% regular euclidian distance 
distance= sqrt((x-cpx).^2+(y-cpy).^2)*1e-3; % km

% extract station with data for the current year
SD          = readtable(HDDfile,'Sheet','Data');
Odv         = datevec(SD.Date+ 693960);
SD          = SD(Odv(:,1) == yyyy,:);

% loop through the stations from closest to furthest away to find the 
have_data   = 0;
while have_data<1
    st          = find(distance==min(distance));
    ID          = St.Stnr(st);
    
    found = SD(SD.St_no==ID & ~isnan(SD.TAM),:);
    
    if height(found)>300
        fprintf(' Using observation: \n%i %s\n',ID,char(St.Name(st)))
        fprintf(' Km away from Domain center: %i\n',round(min(distance)))
        fprintf(' Data points at this station %i\n',height(found))
        have_data = 10;
    else
        fprintf('Nearest observation to Domain center:\n%i %s\n',ID,char(St.Name(st)))
        fprintf('Km away from Domain center: %i\n',round(min(distance)))
        warning(sprintf('Not enough data at this station %i Data threshold set to 300 days',height(found)))
        distance(st) = distance(st)+1e6;
    end
    
end

OBS = inpaint_nans(SD.TAM(SD.St_no==ID));


% % read in the full observations set
% [SD,~,SDT]=xlsread(HDDfile,'Data');
% 
% % Extract the best fit station
% I=SD(:,1)==ID;
% station=SD(I,:);
% 
% % Extract the correct year
% OBS=station(I,3);
% OBS=inpaint_nans(OBS);

D=max(Htres-OBS,0);
%D=D(1:length(dn));
TVHDD=interp1(dn,D,dnew,'METHOD','extrap');
TVHDD(TVHDD<0)=0;
%TVHDD=TVtemp/mean(TVtemp);
% TVn=TVtemp'.*TV;

%--------------------------------------------------------------------------

% Matlab has sunday as the first weekday change to monday:
wd=weekday(dnew)-1;
wd(wd==0)=7;

dv=datevec(dnew);

% Find the weekdays and hours to calculate emissions
wL=unique(wd);
Hrs=unique(dv(:,4));

% The hourly burning cylce for weekdays and weekend days for Norway.  This
% is taken after the Opinion (2000) questionaire. Full reference: 
% Kristin Aasestad, (2010) Vedforbruk, fyringsvaner og svevestøv
% Dokumentasjon og resultater fra undersøkelse i Drammen 2006/2007 (in Norwegian)
% HOUR   = [1.00,2.00,3.00,4.00,5.00,6.00,7.00,8.00,9.00,10.0,11.0,12.0,13.0,14.0,15.0,16.0,17.0,18.0,19.0,20.0,21.0,22.0,23.0,24.0];
% week_day = [0.00,0.00,0.00,0.00,0.00,0.07,0.07,0.07,0.07,0.04,0.04,0.04,0.04,0.35,0.35,0.35,0.35,0.95,0.95,0.95,0.95,0.95,0.95,0.00];
% week_end = [0.00,0.00,0.00,0.00,0.00,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.45,0.45,0.45,0.45,0.92,0.92,0.92,0.92,0.92,0.92,0.00];


%--------------------------------------------------------------------------
% Adjusted 5th order polynomial fit to the SSB data. Adjusted 
% NEW tentative Metved diurnal variation 
week_day = [0.44,0.33,0.23,0.14,0.06,0.01,0.02,0.02,0.02,0.04,0.07,0.16,0.25,0.37,0.49,0.61,0.72,0.83,0.91,0.96,0.96,0.91,0.80,0.55];
week_end = [0.44,0.36,0.26,0.17,0.11,0.20,0.21,0.22,0.24,0.26,0.28,0.30,0.34,0.44,0.55,0.68,0.80,0.88,0.96,1.00,1.00,0.94,0.84,0.60];



% The weekday variation monday to sunday
week = [1,1,1,1,1,sum(week_end)/sum(week_day),sum(week_end)/sum(week_day)];

Diurnal_TV=zeros(size(dv,1),1);
for i=1:length(wL)
    I=wd==wL(i);
    Diurnal_TV(I)=week(wL(i));
    for j=1:length(Hrs)
        Ih=dv(:,4)==Hrs(j);
        if wL(i)>5
            Diurnal_TV(I&Ih')=Diurnal_TV(I&Ih')*week_end(Hrs(j)+1);
        else
            Diurnal_TV(I&Ih')=Diurnal_TV(I&Ih')*week_day(Hrs(j)+1);
            
        end
    end
end

% Normalize it to use it with the HDD.
Diurnal_TV=Diurnal_TV/mean(Diurnal_TV);

TVt         = TVHDD.*Diurnal_TV';
TVt(TVt<0)  = 0;
TV          = TVt/sum(TVt);

sum(TV)
min(TV)

figure
subplot(2,3,1)
plot(dnew(1:7*24),Diurnal_TV(1:7*24))
grid on
xlim([dnew(1),dnew(7*24)])
set(gca,'XTick',dnew(1:12:7*24),'XTickLabelRotation',45)
datetick('x','ddd-HH','keeplimits','keepticks')
xlabel('Date')
ylabel('Weight')
title('Weekly/Diurnal')


subplot(2,3,[2,3])
plot(dnew,TVHDD,'r')
set(gca,'XTick',dnew(1:14*24:end),'XTickLabelRotation',45)
xlim([min(dnew),max(dnew)])
datetick('x','mmm-dd','keeplimits','keepticks')
xlabel('Date')
ylabel('Weight')
title(sprintf('HDD %s to %s ',datestr(dnew(1),'yyyy-mm-dd'),datestr(dnew(end),'yyyy-mm-dd')))


subplot(2,3,[4:6])
plot(dnew,TV)
hold on
plot(dnew,TVHDD/sum(TVHDD),'r')
datetick('x')
xlabel('Date')
ylabel(sprintf('Weight based on %i^oC',Htres))
title(sprintf('Hourly emissions weight %i %s',ID,char(St.Name(st))))


fprintf('Normalized function Diurnal_TV: \n Multipy with emissions in timespan \n %s to %s \n',datestr(min(dn)),datestr(max(dn)))
fprintf('To get hourly emissions \n')
end







