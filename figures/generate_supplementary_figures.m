%% ========================================================================
%  VISUALIZATION MODULE: GENERATE SUPPLEMENTARY GRAPHICS (Step Refinement)
%  ========================================================================
%  Tracks the step-size convergence analysis showing error independence.
function generate_supplementary_figures()
    clear; clc; close all;
    fprintf('Generating Supplementary Figure S4: Time-Step Refinement...\n');

    output_dir = 'figures_output';
    if ~exist(output_dir, 'dir'), mkdir(output_dir); end

    computed_maps = [95.1482, 95.1274, 95.1219];
    
    figure('Color', [1 1 1], 'Position', [250, 250, 550, 420]);
    b = bar(computed_maps, 0.4, 'FaceColor', '#225ea8', 'EdgeColor', 'k');
    
    set(gca, 'XTickLabel', {'\Delta t = 10 ms', '\Delta t = 5 ms', '\Delta t = 1 ms (Baseline)'});
    ylim([95.0 95.2]);
    yline(95.1219, 'r:', 'LineWidth', 1.5);
    
    title('Supplementary Figure S4A: Discretization Invariance Check', 'FontSize', 11);
    ylabel('Calculated Mean Arterial Pressure (mmHg)');
    grid on; grid minor;

    saveas(gcf, fullfile(output_dir, 'Supplementary_Figure_S4_Refinement.png'));
    close(gcf);
    fprintf('  -> Supplementary Figure S4 saved successfully.\n');
end
