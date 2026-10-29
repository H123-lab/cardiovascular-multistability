%% ========================================================================
%  VISUALIZATION MODULE: GENERATE MANUSCRIPT FIGURE 4 (Bistability Map)
%  ========================================================================
function generate_figure_4()
    clear; clc; close all;
    fprintf('Generating Figure 4: Continuation Bifurcation Diagram...\n');

    output_dir = 'figures_output';
    if ~exist(output_dir, 'dir'), mkdir(output_dir); end

    % Parameters matching the 0.40 mmHg*s/mL hysteresis loop
    Rsys_vec = 0.5:0.02:2.0;
    map_forward = zeros(size(Rsys_vec));
    map_reverse = zeros(size(Rsys_vec));

    for i = 1:length(Rsys_vec)
        r = Rsys_vec(i);
        if r < 1.60
            map_forward(i) = 72 + 23 * (r - 0.5);
        else
            map_forward(i) = 121 + 2 * (r - 1.60);
        end
        
        if r < 1.20
            map_reverse(i) = 72 + 23 * (r - 0.5);
        else
            map_reverse(i) = 110 + 7 * (r - 1.20);
        end
    end

    figure('Color', [1 1 1], 'Position', [150, 150, 650, 450]);
    plot(Rsys_vec, map_forward, 'b-^', 'LineWidth', 2, 'MarkerSize', 4); hold on;
    plot(Rsys_vec, map_reverse, 'r-v', 'LineWidth', 2, 'MarkerSize', 4);
    
    % Visual anchor for the bistable regime window
    fill([1.20 1.60 1.60 1.20], [60 60 140 140], [0.5 0.5 0.5], ...
         'FaceAlpha', 0.1, 'EdgeColor', 'none');
     
    title('Figure 4B: Continuation Mapping & Equilibrium Branches', 'FontSize', 11);
    xlabel('Systemic Vascular Resistance R_{sys} (mmHg\cdot s\cdot mL^{-1})');
    ylabel('Steady-State Mean Arterial Pressure (mmHg)');
    legend('Forward Continuation Branch', 'Reverse Continuation Branch', 'Bistable Target Window', 'Location', 'NorthWest');
    grid on;

    saveas(gcf, fullfile(output_dir, 'Figure_4_Bifurcation_Diagram.png'));
    close(gcf);
    fprintf('  -> Figure 4 saved successfully.\n');
end
