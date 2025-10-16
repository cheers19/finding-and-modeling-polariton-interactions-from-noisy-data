directory = dir('Q:\Haim\X-ray SPP files');
maximum_count=[];
idler_energy=[];
ii=0;

i_start=178; % this corresponds to scan 85 in 111 plane
i_finish=216;

pathname = join([directory(i_start).folder,'\']);
    file=join([pathname,directory(i_start).name]);
    Data=nxsLoad_haim(file);
    [sum_of_images, image_vec] = haim_total_sum(Data);

figure()
    imagesc(sum_of_images); 
    caxis([0 2050])
    title('scan-averaged image. Choose ROI (TL and RB)')  % haim: how is result_image "averaged"? it's just a sum...
    [ROI_sig_start(1,:) ROI_sig_start(2,:)] = ginput(2);
    close

    ROI_sig_subt(1,1)=ROI_sig_start(1,1)+25;
    ROI_sig_subt(1,2)=ROI_sig_start(1,2)+25;
    ROI_sig_subt(2,1)=ROI_sig_start(2,1);
    ROI_sig_subt(2,2)=ROI_sig_start(2,2);    

for i = i_start:i_finish
    flag=0;
    try
    pathname = join([directory(i).folder,'\']);
    file=join([pathname,directory(i).name]);
    Data=nxsLoad_haim(file); % load the data of a scan named: 'Aluminum222_pdc_00' num2str(j) '.nxs' ...(for example)
    
    [sum_of_images, image_vec] = haim_total_sum(Data);

    
    signal_pdc1 = squeeze(sum(sum(image_vec(ROI_sig_start(2,1):ROI_sig_start(2,2), ROI_sig_start(1,1):ROI_sig_start(1,2),:))));
    noise=squeeze(sum(sum(image_vec(ROI_sig_subt(2,1):ROI_sig_subt(2,2), ROI_sig_subt(1,1):ROI_sig_subt(1,2),:))))/(ROI_sig_subt(2,2)-ROI_sig_subt(2,1))/(ROI_sig_subt(1,2)-ROI_sig_subt(1,1));
    
    
    signal_clean=signal_pdc1-noise*(ROI_sig_start(2,2)-ROI_sig_start(2,1))*(ROI_sig_start(1,2)-ROI_sig_start(1,1));
    % errorbar(Data.scan_motor_values,signal_clean,sqrt(signal_clean))
    if directory(i).bytes > 1000000
    flag = 1;
    index = find(signal_clean(:, 1) == max(signal_clean(:, 1)));
    index_maximum = index(1,1);
    max_count = signal_clean(index_maximum);
%     max_2theta = scan_vector(index_maximum);
    idler = Data.idler_energy;
    end
    

maximum_count = [maximum_count,max_count]; 
idler_energy = [idler_energy,idler];
end
end

figure()
plot(idler_energy, maximum_count,'b--o')
errorbar(idler_energy,maximum_count,sqrt(maximum_count))
title('spectral graph')
