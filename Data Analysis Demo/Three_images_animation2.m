% --- Setup ---
base_dir = 'Q:\Haim\X-ray SPP files';
output_dir = 'Q:\Haim\X-ray SPP analysis';
h5_scan_path = '/root.spyc.config1d_RIXS_0024/scan_data/';

% Ensure the output directory exists
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

try
    directory = dir(base_dir);
catch ME
    error('Failed to read directory: %s\n%s', base_dir, ME.message);
    return;
end

% Define file indices to process
i1 = 10:126; 

% Pre-allocate arrays for efficiency
% We don't know the exact count, so pre-allocate to max possible size
index_maximum = zeros(length(i1), 1); 
ii = 0; % Counter for valid files

% --- Figure Setup for Speed ---
% Create the figure once and make it invisible.
% Plotting to an invisible figure is much faster than rendering to screen.
fig = figure(50);
fig.Visible = 'off';
disp('Starting file processing...');

% --- Main Processing Loop ---
% Loop directly over the desired indices. This is much cleaner.
for i = i1
    
    current_file_info = directory(i);
    file = fullfile(current_file_info.folder, current_file_info.name);
    
    % Use a try-catch block to handle errors gracefully
    % This will report errors and continue to the next file
    try
        % --- Data Loading ---
        Data = nxsLoad_haim(file); % Load main data

        % Load only the data you need. 
        % The 'haim_total_sum' function call was removed as it was unused.
        [sum_of_images_DividedTime, image_vec_DividedTime] = sum_DividedTime(Data);

        % Load HDF5 data
        rocking_curve_reference = h5read(file, [h5_scan_path 'data_04']);
        scan_vector = h5read(file, [h5_scan_path 'actuator_1_1']);

        % --- Data Processing ---
        
        % Determine the correct x-axis data for the plot
        x_data = scan_vector; % Default
        if isfield(Data, 'Scan_motor_name') && isfield(Data, 'pump_energy') && ...
           strcmp(Data.Scan_motor_name, 'rixs_energy')
       
            x_data = scan_vector - double(Data.pump_energy);
        end

        % Process only if file is large enough (as in original code)
        if current_file_info.bytes > 1000000
            ii = ii + 1;
            
            % Find the index of the maximum value (more efficient than find(==max))
            [~, max_idx] = max(rocking_curve_reference);
            index_maximum(ii) = max_idx(1); % Use first max if multiple
        else
            % Skip this file if it's too small, or handle as needed
            % Note: The original code would fail here if ii was not incremented,
            % as 'index_maximum(ii)' would not be defined for the plot.
            % We'll skip plotting if the file is too small.
            warning('Skipping file (too small): %s', file);
            continue; 
        end
        
        % Get names for titles
        name_of_file = correct_number_scan(current_file_info.name);
        name_of_motor = correct_name(Data.Scan_motor_name);

        % --- Plotting ---
        clf(fig); % Clear the figure for the new plot

        subplot(2,2,1);
        imagesc(image_vec_DividedTime(:, :, index_maximum(ii))); 
        caxis([0 100]);
        title([name_of_file, ' peak [counts/s]']);
        colorbar;

        subplot(2,2,2);
        imagesc(sum_of_images_DividedTime); 
        caxis([0 1270]);
        title([name_of_file, ' [counts/s]']);
        colorbar;

        subplot(2,2,[3,4]);
        plot(x_data, rocking_curve_reference, 'LineWidth', 1.5);
        grid on;
        
        % Dynamic title building (replaces the giant if/elseif block)
        title_parts = {['scan:', name_of_motor]};
        if isfield(Data, 'sample_thetah') && ~isempty(Data.sample_thetah)
            title_parts{end+1} = [', theta:', num2str(Data.sample_thetah)];
        end
        if isfield(Data, 'rixs_delta1') && ~isempty(Data.rixs_delta1)
            title_parts{end+1} = [', 2theta:', num2str(Data.rixs_delta1)];
        end
        if isfield(Data, 'idler_energy') && ~isempty(Data.idler_energy)
            title_parts{end+1} = [', idler:', num2str(Data.idler_energy), 'eV'];
        end
        title(strjoin(title_parts, ''));
        xlabel('Scan Vector');
        ylabel('Intensity');
        
        % --- Saving Figure ---
        filenameScans = fullfile(output_dir, [name_of_file '.jpg']);
        saveas(fig, filenameScans);
        
    catch ME
        % Report the error and continue to the next file
        warning('Failed to process file: %s\nError: %s', ...
                current_file_info.name, ME.message);
    end
    
    % Optional: Update progress
    % fprintf('Processed file %d of %d: %s\n', i, i1(end), current_file_info.name);
    
end % End of main loop

% --- Cleanup ---
fig.Visible = 'on'; % Show the last plot
index_maximum = index_maximum(1:ii); % Trim unused part of the array

disp('---');
disp(['Processing complete. ', num2str(ii), ' files processed and saved.']);