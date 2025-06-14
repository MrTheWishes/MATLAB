function solar_gui()
    % Load the background image used for GUI aesthetics
    bg_img = imread('C:\Users\ASUS\OneDrive\Desktop\5th\matlab\2.png');

    % Create the main GUI window
    fig = figure('Name', 'Solar Cell Analysis', 'NumberTitle', 'off', ...
                 'Position', [500 300 400 300]);

    % Add a signature text box at the bottom-right of the main window
    annotation(fig, 'textbox', [0.36 0.01 0.64 0.05], ...
               'String', 'Designed by Bader ALJEBAEI (HIAST 2025)', ...
               'HorizontalAlignment', 'right', ...
               'EdgeColor', 'none', 'FontSize', 8, 'Color', [0.3 0.3 0.3]);

    % Place the background image behind all controls
    bg_ax = axes(fig, 'Units', 'normalized', 'Position', [0 0 1.29 1]);
    imshow(bg_img, 'Parent', bg_ax);
    axis(bg_ax, 'off');
    uistack(bg_ax, 'bottom');

    % --- GUI Controls ---
    % Text label and button to select input data file
    uicontrol('Style', 'text', 'Position', [30 250 120 25], 'String', 'Select Data File:');
    uicontrol('Style', 'pushbutton', 'Position', [160 250 200 25], ...
              'String', 'Browse', 'Callback', @load_file);

    % Input fields for solar cell width and length
    uicontrol('Style', 'text', 'Position', [30 200 120 25], 'String', 'Cell Width (cm):');
    width_edit = uicontrol('Style', 'edit', 'Position', [160 200 200 25]);

    uicontrol('Style', 'text', 'Position', [30 160 120 25], 'String', 'Cell Length (cm):');
    length_edit = uicontrol('Style', 'edit', 'Position', [160 160 200 25]);

    % Button to start the analysis after input
    uicontrol('Style', 'pushbutton', 'Position', [100 100 200 30], ...
              'String', 'Run Analysis', 'Callback', @run_analysis);

    % Shared variable to hold loaded data
    data = [];

    % Callback: load IV data file
    function load_file(~, ~)
        [file, path] = uigetfile('*.txt', 'Select IV Data File');
        if isequal(file, 0), return; end
        full_path = fullfile(path, file);
        data = readmatrix(full_path, 'Delimiter', ';');
        msgbox('Data file loaded successfully.', 'Success');
    end

    % Callback: run analysis after input and validation
    function run_analysis(~, ~)
        if isempty(data)
            errordlg('Please load a data file first.', 'Error');
            return;
        end

        % Validate numeric inputs for width and length
        try
            W = str2double(get(width_edit, 'String'));
            L = str2double(get(length_edit, 'String'));
            Area = W * L;
            if isnan(Area) || Area <= 0, error('Invalid area.'); end
        catch
            errordlg('Please enter valid cell dimensions.', 'Error');
            return;
        end

        % Show progress bar during processing
        wait = waitbar(0, 'Initializing analysis...');
        for step = 1:10
            pause(0.05);  % artificial delay to simulate loading
            waitbar(step / 10, wait, sprintf('Processing... %d%%', round(step*10)));
        end

        % --- Begin data processing ---
        V = data(:,1);            % Voltage values
        I_data = data(:,2);       % Measured current values
        q = 1.602e-19;            % Elementary charge [C]
        k = 1.381e-23;            % Boltzmann constant [J/K]
        T = 300;                  % Absolute temperature [K]

        % Define diode model equation (nonlinear implicit equation)
        diode_model = @(params, V) arrayfun(@(v) fsolve( ...
            @(i) i - params(1) + ...
                   params(2)*(exp(q*(v + i*params(3))/(params(4)*k*T)) - 1) + ...
                   (v + i*params(3))/params(5), ...
            0, optimoptions('fsolve','Display','off')), V);

        % Initial guess and parameter bounds
        initial_guess = [5e-2, 1e-9, 1, 1, 1000];  % Iph, I0, Rs, n, Rsh
        lb = [0, 0, 0, 0.5, 1];                   % Lower bounds
        ub = [1, 1e-6, 10, 3, 1e5];                % Upper bounds

        % Fit the model to the measured data
        opts = optimoptions('lsqcurvefit', 'Display', 'off', 'MaxFunctionEvaluations', 5000);
        params_fit = lsqcurvefit(diode_model, initial_guess, V, I_data, lb, ub, opts);

        % Evaluate the fitted model
        I_fit = diode_model(params_fit, V);

        % Calculate electrical performance parameters
        P = V .* I_data;               % Power at each point
        Pmax = max(P);                 % Maximum power
        Isc = I_data(find(V == 0, 1)); % Short-circuit current
        [~, Voc_idx] = min(abs(I_data));
        Voc = V(Voc_idx);             % Open-circuit voltage
        FF = Pmax / (Isc * Voc);      % Fill Factor
        Pin = Area * 0.1;             % Input power based on irradiance
        Efficiency = (Pmax / Pin) * 100; % Efficiency [%]

        % Statistical goodness of fit metrics
        residuals = I_data - I_fit;
        SS_res = sum(residuals.^2);                  % Residual sum of squares
        SS_tot = sum((I_data - mean(I_data)).^2);    % Total sum of squares
        R_squared = 1 - (SS_res / SS_tot);           % R²
        RMSE = sqrt(mean(residuals.^2));             % Root Mean Square Error
        MAE = mean(abs(residuals));                  % Mean Absolute Error
        close(wait);  % Close waitbar

        % --- Display Results Window ---
        results_fig = figure('Name', 'Results', 'NumberTitle', 'off', ...
                             'Position', [300 100 900 600], 'Color', 'white');
        bg_ax = axes(results_fig, 'Units', 'normalized', 'Position', [0 0 1 1]);
        imshow(bg_img, 'Parent', bg_ax);
        axis(bg_ax, 'off');
        uistack(bg_ax, 'bottom');

        % Plot the IV curve (measured vs fitted)
        ax1 = axes('Parent', results_fig, 'Position', [0.07 0.12 0.65 0.8]);
        plot(ax1, V, I_data, 'o', V, I_fit, '-');
        xlabel(ax1, 'Voltage (V)');
        ylabel(ax1, 'Current (A)');
        title(ax1, 'IV Curve');
        legend(ax1, 'Measured', 'Fitted');

        % Display model parameters
        annotation(results_fig, 'textbox', [0.72 0.70 0.25 0.15], 'String', ...
            {sprintf('Iph: %.2e A', params_fit(1)), ...
             sprintf('I0: %.2e A', params_fit(2)), ...
             sprintf('Rs: %.2f Ω', params_fit(3)), ...
             sprintf('n: %.2f', params_fit(4)), ...
             sprintf('Rsh: %.2f Ω', params_fit(5))}, ...
            'EdgeColor', 'none', 'FontSize', 10, 'Color', 'k', 'BackgroundColor', 'white');

        % Display performance and fit metrics
        annotation(results_fig, 'textbox', [0.72 0.48 0.25 0.15], 'String', ...
            {sprintf('FF: %.2f', FF), ...
             sprintf('Efficiency: %.2f%%', Efficiency), ...
             sprintf('R²: %.4f', R_squared), ...
             sprintf('RMSE: %.4f', RMSE), ...
             sprintf('MAE: %.4f', MAE)}, ...
            'EdgeColor', 'none', 'FontSize', 10, 'Color', 'k', 'BackgroundColor', 'white');

        % Signature at the bottom of the results window
        annotation(results_fig, 'textbox', [0.6 0.01 0.4 0.04], ...
                   'String', 'Designed by Bader ALJEBAEI (HIAST 2025)', ...
                   'HorizontalAlignment', 'right', ...
                   'EdgeColor', 'none', 'FontSize', 8, 'Color', [0.3 0.3 0.3]);

        % Ask user to save the result to a .txt file
        [saveFile, savePath] = uiputfile('*.txt', 'Save IV Data As');
        if isequal(saveFile, 0), return; end
        fullSavePath = fullfile(savePath, saveFile);
        fid = fopen(fullSavePath, 'w');

        % Write results to file
        fprintf(fid, 'Solar Cell Analysis Results\n');
        fprintf(fid, '----------------------------\n');
        fprintf(fid, 'Iph = %.5e A\n', params_fit(1));
        fprintf(fid, 'I0 = %.5e A\n', params_fit(2));
        fprintf(fid, 'Rs = %.3f Ohm\n', params_fit(3));
        fprintf(fid, 'n = %.3f\n', params_fit(4));
        fprintf(fid, 'Rsh = %.3f Ohm\n', params_fit(5));
        fprintf(fid, 'Fill Factor (FF) = %.2f\n', FF);
        fprintf(fid, 'Efficiency = %.2f %%\n', Efficiency);
        fprintf(fid, 'R² = %.4f\n', R_squared);
        fprintf(fid, 'RMSE = %.4f\n', RMSE);
        fprintf(fid, 'MAE = %.4f\n', MAE);
        fprintf(fid, '----------------------------\n');
        fprintf(fid, 'Voltage (V)\tCurrent (A)\n');
        for i = 1:length(V)
            fprintf(fid, '%.6f\t%.6f\n', V(i), I_fit(i));
        end
        fclose(fid);

        % Save the IV curve figure as a PNG image
        f = figure('Visible', 'off');
        plot(V, I_data, 'o', V, I_fit, '-');
        xlabel('Voltage (V)');
        ylabel('Current (A)');
        title('IV Curve');
        legend('Measured', 'Fitted');
        saveas(f, fullfile(savePath, 'IV_Curve.png'));
        close(f);
    end
end
