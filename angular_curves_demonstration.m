%%%spectrum builder for SOLEIL 

% clear 
%% parameters

global pathname filename m re q e0 mu0 hp hbar h_eV c Na pump_energy;
m = 9.10938291*10^(-31); %electron mass
re = 2.817940*10^(-15); %classical electron radius, meters
q = 1.60217657*10^(-19); %electron charge
e0 = 8.85418781*10^(-12); %????
mu0 = 4*pi*10^(-7); %
hp = 6.6260695*10^(-34); %Plank's constant
hbar = hp/(2*pi); %you know...
h_eV = 4.1357e-15; %Plank in eV
c = 299792458; %speed of love
Na = 6.022140857*10^23; %Avogadro number
pump_energy = 9978; %pump energy, eV

%% choose ROI for signal and substruction manually. Otherwise run the mode 0.
% Note that the ROI might differ when you change reflections. That's what
% happened in Aluminum experiment. We changed reflection from (200) to
% (400) and the signal peak at images shifted and the original ROI didn't
% cover them completely so it affected the results. Pay attention to that. 

% X_naught_sub = 310;
% Y_naught_sub = 280;
% Y_naught = 288;

% X_naught_sub = 310;
% Y_naught_sub = 270;
% 
% X_length_sub = 8;
% Y_length_sub = 31;
% 
% ROI_substr = [X_naught_sub X_length_sub+X_naught_sub; Y_naught_sub Y_naught_sub+Y_length_sub];
% 
% %%%%%%%%%
% 
% %choose ROI for signal
% 
% % X_naught_sig = 299;
% % Y_naught_sig = 280;
% 
% X_naught_sig = 299; %for (200)
% Y_naught_sig = 270;
% % 
% % X_naught_sig = 292; %for (400)
% % Y_naught_sig = 270;
% 
% X_length_sig = 8;
% Y_length_sig = 31;
% 
% ROI_sig = [X_naught_sig X_length_sig+X_naught_sig; Y_naught_sig Y_naught_sig+Y_length_sig];
% 

%% Choose a mode: 
% 0 check if ROI covers the right area
% 1 spectrum builder
% If you choose 0, you need to specify the scan. It means that you need to
% upload the exact data file in the dialog window that will be opened. You
% can add operating modes for your needs. Simply put another elseif after
% the last one.
message = ('choose operating mode:');
operating_mode = input(message);

%% ROI definition mode
% choose this mode first to define ROI
if operating_mode == 0
    
    % we are choosing ROI for the signal and subtruct another ROI (a
    % background ROI) from this signal ROI so we'll be left with only the
    % signal itself
    [filename, pathname]=uigetfile('Interactive mode data:');%calls browser to choose the data file *.nxs or whatever they're using. Choose all files in file type.
    rot_angle = -90; %rotation of the image by this angle, degrees. So the image would look like on the beamline
    
    h5readatt([pathname filename], '/root.spyc.config1d_RIXS_0024/scan_data/actuator_1_1','alias')
    
    [result_image] = roi_definition(filename, pathname, rot_angle); % this compute the sum along the third dimension of image_vec (image_vec was made from 'dataset' and was rotated by the rot_angle (dataset was made from pathname,filename)) which is the number of images: 51
    
    figure(1)
    imagesc(result_image)
    title('scan-averaged image. Choose ROI (TL and RB)')  
    [ROI_sig(1,:) ROI_sig(2,:)] = ginput(2)
    close
    
    figure(2)
    imagesc(result_image)
    title('scan-averaged image. Choose ROI (TL and RB)')
    [ROI_substr(1,:) ROI_substr(2,:)] = ginput(2)
    close
    
%% ROI verification mode
% returns three pictures: the first one is the scan-average image that
% shows where the signal hits the camera, the second one shows where the
% signal ROI is and the third one - what you substract. 
% Also it shows the corresponding rocking curves for validation that you
% haven't messed anything up.
elseif operating_mode == 1    

    [result_clean_signal, result_image, result_image_roi_sig, result_image_roi_sub, rocking_curve_roi_sig, rocking_curve_reference, rocking_curve_substaction, scan_vector] =...
        roi_verification(filename, pathname, ROI_substr, ROI_sig, rot_angle);
    
    figure(10)
    subplot(1,3,1), imagesc(result_image)
    daspect([1 1 1])
    title('scan-averaged image')
    subplot(1,3,2), imagesc(result_image_roi_sig)
    daspect([1 1 1])
    title('signal ROI is hidden')
    subplot(1,3,3), imagesc(result_image_roi_sub)
    daspect([1 1 1])
    title('substraction ROI is hidden')
    
    figure(20)
    subplot(1,4,1), plot(scan_vector, rocking_curve_reference)
    title('beamline reference curve')
    subplot(1,4,2), plot(scan_vector, rocking_curve_roi_sig)
    title('custom ROI curve')
    subplot(1,4,3), plot(scan_vector, rocking_curve_substaction)
    title('substraction ROI curve')
    subplot(1,4,4), plot(scan_vector, result_clean_signal)
    title('clean signal')

%% animation of the images
elseif operating_mode == 10

    series_num = 5; %choose the number of the series of measurements. 
    scan_file_name = ['scan_numbers' num2str(series_num) '.txt'];
    scan_numbers = load(scan_file_name); %those are the numbers of scans that will be used to build a spectrum
    animation_resulting_images
elseif operating_mode == 2
%% Spectra builder mode. 
% Specify the series of scans in the corresponding variable series_num. The
% file containing the scan numbers should be located in the program folder and
% follow the pattern scan_number%series_num%.txt. If not, correct the
% variable scan_file_name.
    series_num = 5; %choose the number of the series of measurements. 
    scan_file_name = ['scan_numbers' num2str(series_num) '.txt'];
    scan_numbers = load(scan_file_name); %those are the numbers of scans that will be used to build a spectrum
    [pathname]=uigetdir('Interactive mode data:');%calls browser to choose the data file *.nxs or whatever they're using. Choose all files in file type.
    rot_angle = -90; %rotation of the image by this angle, degrees. So the image would look like on the beamline
    
    % The following function will return you
    % 1) vector of idler energies (x-axis of your spectrum)
    % 2) set of rocking curves that you saw on the beamline
    % (rocking_curve_reference)
    % 3) set of rocking curve with the ROI that you have chosen
    % (rocking_curve_user)
    % 4) set of rocking curves for substraction (rocking_curve_substaction)
    
    [idler_energy_vector, rocking_curve_roi_sig, rocking_curve_reference, rocking_curve_substaction, scan_vector, acq_time] =...
        rocking_curve_extractor (pathname, scan_numbers, ROI_substr, ROI_sig, rot_angle);
    
    %% Power spectrum
    % The following calculates the power spectrum. It returns the spectra AFTER
    % the substraction of the background curves.
    [clean_signal_curve_user, clean_signal_curve_reference, PDC_spectrum_reference, error_bar_reference, PDC_spectrum_user, error_bar_user] =...
        spectrum_builder(rocking_curve_roi_sig, rocking_curve_reference, rocking_curve_substaction, idler_energy_vector);
    
    PDC_spectrum_reference = PDC_spectrum_reference/acq_time(1); %this is to make everything in c.p.s.
    error_bar_reference = error_bar_reference/acq_time(1) ;
    PDC_spectrum_user = PDC_spectrum_user/acq_time(1) ;
    error_bar_user = error_bar_user/acq_time(1) ;
    
    figure(30)
    subplot(1,2,1), errorbar(idler_energy_vector, PDC_spectrum_reference, error_bar_reference)
    title('beamline reference spectrum')
    subplot(1,2,2), errorbar(idler_energy_vector, PDC_spectrum_user, error_bar_user)
    title('custom ROI spectrum')
    
    %% Peak position spectrum
    % This part makes a spectrum of peak positions. The method is the
    % very tricky and most likely needs to be developed for the specific
    % experiment. However, this works more or less well for the results
    % from the Aluminum experiment. The method is the following: on the
    % substraction curve there is a Bragg peak (see variable
    % rocking_curve_substaction). I find the position of the peak and
    % analyse only points on the rocking cuvre with the signal _before_ the
    % this position in order to throw out possible contribution of the
    % Bragg. Then I find the gravity center of the curve (center of mass).
    % Pay attention to: the theta angles in the current data goes to
    % negative values, meaning that the scan goes from higher angles to
    % lower, in other words signal goes first and then Bragg. If it changes
    % - modify the function accordnigly. Check the curves that the function
    % analyses (I'll indicate it further) so that the curve looks OK and no
    % Bragg contribution is present. Otherwise, the position will be
    % shifted to the Bragg which is not cool. pp means peak position. 
    
    [analysed_rocking_curves_user, analysed_rocking_curves_reference, ppspectrum_reference, ppspectrum_user, scan_vector_analyzed] =...
        ppspectrum_builder(rocking_curve_roi_sig, rocking_curve_reference, rocking_curve_substaction, idler_energy_vector, scan_vector);
    theta_Bragg_measured = 18.3; %specify the _measured_ value of theta Bragg
    
    figure(40)
    subplot(1,2,1), plot(idler_energy_vector, ppspectrum_reference)
    title('beamline reference ppspectrum')
    subplot(1,2,2), plot(idler_energy_vector, ppspectrum_user)
    title('user ROI ppspectrum')
    
    %% Animation
    % Run this section to see the curves
    animation_ppspectrum_rocking_curves
else
    display('Unknown operating mode. Feel free to develop more modes')
end













