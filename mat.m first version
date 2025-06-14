
filename = 'C:\Users\ASUS\OneDrive\Desktop\5th\New folder\DD.txt';
data = readmatrix(filename, 'Delimiter', ';');
V = data(:,1);
I_data = data(:,2);

q = 1.602e-19; 
k = 1.381e-23; 
T = 300;     

diode_model = @(params, V) arrayfun(@(v) fsolve( ...
    @(i) i - params(1) + params(2)*(exp(q*(v + i*params(3))/(params(4)*k*T)) - 1) + (v + i*params(3))/params(5), ...
    0, optimoptions('fsolve','Display','off')), V);


initial_guess = [5e-2, 1e-9, 1, 1, 1000];

opts = optimoptions('lsqcurvefit', 'Display', 'iter', 'MaxFunctionEvaluations', 5000);
lb = [0, 0, 0, 0.5, 1];  % Lower bounds
ub = [1, 1e-6, 10, 3, 1e5];  % Upper bounds

params_fit = lsqcurvefit(diode_model, initial_guess, V, I_data, lb, ub, opts);

Iph = params_fit(1);
I0 = params_fit(2);
Rs = params_fit(3);
n = params_fit(4);
Rsh = params_fit(5);


I_fit = diode_model(params_fit, V);


figure;
plot(V, I_data, 'o', 'DisplayName', 'Measured');
hold on;
plot(V, I_fit, '-', 'DisplayName', 'Fitted');
xlabel('Voltage (V)');
ylabel('Current (A)');
legend;
title('Solar Cell IV Characteristics and Fit');


fprintf('\nFitted Parameters:\n');
fprintf('Photocurrent (Iph): %.4e A\n', Iph);
fprintf('Saturation Current (I0): %.4e A\n', I0);
fprintf('Series Resistance (Rs): %.4f Ohm\n', Rs);
fprintf('Ideality Factor (n): %.3f\n', n);
fprintf('Shunt Resistance (Rsh): %.2f Ohm\n', Rsh);


P = V .* I_data;
Pmax = max(P);
Isc = I_data(find(V==0,1)); % Short-circuit current
[~, Voc_idx] = min(abs(I_data)); 
Voc = V(Voc_idx);
FF = Pmax / (Isc * Voc);
Pin = 1; 
Efficiency = Pmax / Pin;

fprintf('Isc: %.4e A\n', Isc);
fprintf('Voc: %.3f V\n', Voc);
fprintf('Fill Factor (FF): %.3f\n', FF);
fprintf('Efficiency: %.2f %%\n', Efficiency*100);

% ------------------ Evaluation Metrics ------------------

% Residuals
residuals = I_data - I_fit;

% R-squared
SS_res = sum(residuals.^2);
SS_tot = sum((I_data - mean(I_data)).^2);
R_squared = 1 - (SS_res / SS_tot);

% RMSE
RMSE = sqrt(mean(residuals.^2));

% MAE
MAE = mean(abs(residuals));

% Display metrics
fprintf('\nFit Quality Metrics:\n');
fprintf('R-squared: %.4f\n', R_squared);
fprintf('RMSE: %.4e A\n', RMSE);
fprintf('MAE: %.4e A\n', MAE);


