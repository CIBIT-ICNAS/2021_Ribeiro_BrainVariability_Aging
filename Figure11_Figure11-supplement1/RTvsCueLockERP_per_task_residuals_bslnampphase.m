% adjusting ERP amplitude for phase of ongoing slow fluctuations and
% checking correlation with RT
clear; close all;
% participants id
% eeg included participants
young_eeg=[4	6	9	10	13	15	16	25	26	28	31	33	34	36	42	44	45	46	50	51	53	54	56	59	62	66	68	72	74	76	78	80	81	82	84	85];
older_eeg=[7   8	11	12	14	17	19	20	21	22	23	32	35	37	38	41	43	47	48	49	52	55	57	58	61	63	64	65	67	69	70	71	73	75	77	79	83	86];

group = {young_eeg, older_eeg};
task={'D1', 'D2', 'G1', 'G2'};

% open eeglab
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

coeff_robust_chan = cell(2, 2);
for grp = 1:2
    part = 0;
    for p = group{grp}
        part = part + 1;
        % clear eeglab
        STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG=[]; CURRENTSET=[];
             
        % erp data - dependent variable
        eeg_directory = strcat('G:\ProjectAgingNeuromodulation\AuditoryResearch\AuditoryTask_EyeTracking_EEG_lab94\AB', num2str(p), '\EEG\');

        % create variable with data electrodes X time frames X trials -
        % starting at cue onset
        epochs_erp = {}; FCz_erp = {}; RT_incl = {}; cue2target_interval_inc = {};
       for t = 1:4
             % clear eeglab
            STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG=[]; CURRENTSET=[];
            %load file - from eeglab_analysis_2b_synchronize_pupil
            % _RefM1M2_RemEKG_EMG_Fps_ChanLocs_RemBadCh_ica_ArtICsRem_Filt0_1_35Hz_Pupil.set
            % manual/visual removal of periods with artifacts
            % save as ..._Filt0_1_35Hz_Pupil_ManualArtRej.set
            if p == 77 && ismember(t, [1, 2])
                filename=strcat('AB', num2str(p), '_', task{t}, '_Filt0_1_35Hz_Pupil_ManualArtRej_HEO.set');
            else
                filename=strcat('AB', num2str(p), '_', task{t}, '_Filt0_1_35Hz_Pupil_ManualArtRej.set');
            end
            EEG = pop_loadset(filename, eeg_directory);
            % epoch data
            EEG = pop_epoch( EEG, {  '1'  }, [-.2  6]);
           
           % interpolate bad channels removed earlier
            if length(EEG.chanlocs)<67 && p ~= 6 && p~=38 % these participants do not have eyetracking data but have all channels ok
                [EEG] = interpol( EEG);
            end
           
           % calculate reaction time for every trial and error trials to
           % exclude
           
            clear epoch_event;
            epoch_event=zeros(size(EEG.event, 2), 3);

            for e=1:size(EEG.event, 2)
                epoch_event(e, 1)=EEG.event(e).epoch;
                epoch_event(e, 2)=str2double(EEG.event(e).type);
                epoch_event(e, 3)=EEG.event(e).latency;
            end

            cue_only_correct_trial=[];
            correct_trial=[];
            response2cue=[];
            multiple_responses=[];
            misses=[];
            response2cue=[];
            RT=[];
            slow_responses=[];
            slow_RT=[];
            cue2target_interval = [];
            response2nogo=[];

            for r = 1:epoch_event(end, 1)
                events_per_epoch_index=[];
                events_per_epoch_index=find(epoch_event(:,1)==r);

                events_per_epoch=epoch_event(events_per_epoch_index, 2);
                latencies_per_epoch=epoch_event(events_per_epoch_index, 3);

                if length(events_per_epoch)==1
                    cue_only_correct_trial=[cue_only_correct_trial; r];
                else
                    if events_per_epoch(2)==2 && events_per_epoch(3)==5 && length(events_per_epoch)==3
                        correct_trial=[correct_trial; r];
                        RT=[RT; r (latencies_per_epoch(3)-latencies_per_epoch(2))*1000/500]; 
                        cue2target_interval = [cue2target_interval; r (latencies_per_epoch(2)-latencies_per_epoch(1))*1000/500];
                    elseif events_per_epoch(2)==2 && events_per_epoch(3)==5 && events_per_epoch(4)==3 
                        slow_responses=[slow_responses; r];
                        slow_RT=[slow_RT; r (latencies_per_epoch(3)-latencies_per_epoch(2))*1000/500];
                    elseif events_per_epoch(2)==5
                        response2cue=[response2cue; r];
                    elseif length(events_per_epoch)>3 && events_per_epoch(2)==2 && events_per_epoch(3)==5 && events_per_epoch(4)==5
                        multiple_responses=[multiple_responses; r]; 
                    elseif events_per_epoch(2)==2 && events_per_epoch(3)==3
                        misses=[misses; r];
                    elseif length(events_per_epoch)>=3 && (events_per_epoch(2)==4 && events_per_epoch(3)==6 && t>2)
                        response2nogo=[response2nogo; r];  
                    end
                end 
            end

            % exclude error trials and trials after error - there is a problem
            % where chunks of EEG with muscle artifact were removed trials
            % after error might NOT immediately follow an error - shoudl check
            % with urevent - note that error trials are very rare
            % error_trials - all errors, response2cue, multiple responses, misses, slow responses
            error_trials=cat(1, misses, multiple_responses, response2cue, slow_responses, response2nogo);
            % only correct go trials, excluding trials after error
            include_epochs = setdiff(correct_trial, error_trials+1);
            
            cnt = 0;
            for inc = include_epochs'
                cnt = cnt + 1;
                RT_incl{t}(cnt, 1) = RT(RT(:, 1) == inc, 2);
    %             cue2target_interval_inc{t}(cnt, 1) = cue2target_interval(cue2target_interval(:, 1) == inc, 2);
            end
            
            
            EEG = pop_select( EEG, 'trial',include_epochs);
            % create variable with average EEG amplitude 200 ms baseline
            % before cue onset
            EEGbsln{t} = squeeze(mean(EEG.data(1:59, 1:99, :), 2)); 
            
            EEG = pop_rmbase( EEG, [-200 0] ,[]);
           % ERP data - avg amplitude between 1000 and 1500 ms after cue onset
           ERPs{t} = squeeze(mean(EEG.data(1:59, 600:850, :), 2)); % chan X trials    
%            ERPs_single_trial{t} = EEG.data(1:59, 1:1100, :); % chan x time x trial
           
           % calculate phase of slow fluctuations at cue onset
           EEG = pop_loadset(filename, eeg_directory);
            % interpolate bad channels removed earlier
            if length(EEG.chanlocs)<67 && p ~= 6 && p~=38 % these participants do not have eyetracking data but have all channels ok
                [EEG] = interpol( EEG);
            end
            % filter data low pass 2 Hz
            EEG = pop_eegfiltnew(EEG, 'hicutoff',2,'plotfreqz',0);
            % hilbert transform
            signal_phase = [];
            for chan = 1:59
                y = hilbert(EEG.data(chan, :));
                signal_phase(chan, :) = angle(y); % extract instantaneous phase
            end

            EEG.data(1:59, :) = signal_phase;
            % epoch data
            EEG = pop_epoch( EEG, {  '1'  }, [-.2  6]);
            EEG = pop_select( EEG, 'trial',include_epochs); % exclude errors etc
           % phase at cue-onset
           EEG_phase_bsln{t} = squeeze(EEG.data(1:59, 100, :)); % chan x trials
           
           
           % calculate amplitude envelop of slow fluctuations at cue onset
           EEG = pop_loadset(filename, eeg_directory);
            % interpolate bad channels removed earlier
            if length(EEG.chanlocs)<67 && p ~= 6 && p~=38 % these participants do not have eyetracking data but have all channels ok
                [EEG] = interpol( EEG);
            end
            % filter data low pass 2 Hz
            EEG = pop_eegfiltnew(EEG, 'hicutoff', 2,'plotfreqz',0);
            % hilbert transform
            signal_amplitude = [];
            for chan = 1:59
                y = hilbert(EEG.data(chan, :));
                signal_amplitude(chan, :) = abs(y); % extract instantaneous amplitude envelop
            end

            EEG.data(1:59, :) = signal_amplitude;
            % epoch data
            EEG = pop_epoch( EEG, {  '1'  }, [-.2  6]);
            EEG = pop_select( EEG, 'trial', include_epochs); % exclude errors etc
           % amplitude envelope at cue-onset
           EEG_amplit_bsln{t} = squeeze(EEG.data(1:59, 100, :)); % chan x trials
        
       end 
       % tasks: simple RT (runs 1 and 2) and gng (runs 3 and 4) 
       
       Res_simpleRT = []; Res_gng = [];
       for chan  = 1:59
           % regress eeg phase effect at baseline out of erp amplitude
           % simple RT
           y = [ERPs{1}(chan, :)'; ERPs{2}(chan, :)'];
           x = [[EEG_amplit_bsln{1}(chan, :)'; EEG_amplit_bsln{2}(chan, :)'].*cos([EEG_phase_bsln{1}(chan, :)'; EEG_phase_bsln{2}(chan, :)']),...
               [EEG_amplit_bsln{1}(chan, :)'; EEG_amplit_bsln{2}(chan, :)'].*sin([EEG_phase_bsln{1}(chan, :)'; EEG_phase_bsln{2}(chan, :)']), ones(length(y), 1)];
           [~,~,Res_simpleRT(:, chan)] = regress(y, x);
           
           % gng
           y = [ERPs{3}(chan, :)'; ERPs{4}(chan, :)'];
           x = [[EEG_amplit_bsln{3}(chan, :)'; EEG_amplit_bsln{4}(chan, :)'].*cos([EEG_phase_bsln{3}(chan, :)'; EEG_phase_bsln{4}(chan, :)']),...
               [EEG_amplit_bsln{3}(chan, :)'; EEG_amplit_bsln{4}(chan, :)'].*sin([EEG_phase_bsln{3}(chan, :)'; EEG_phase_bsln{4}(chan, :)']), ones(length(y), 1)];
           [~,~,Res_gng(:, chan)] = regress(y, x);
       
       end
       
         % create variables for correlation
         % correlate RT with ERP residuals for each channel
         % dependent variable RT
         % simple RT
         DV = [RT_incl{1}; RT_incl{2}];
        for chan = 1:size(ERPs{1}, 1) 
            IV = Res_simpleRT(:, chan);
%             [r,t,h,outid,hboot,CI] = skipped_correlation(IV,DV,1);
            [r,~,~,~,~,~] = skipped_correlation(IV,DV,0);
            coeff_robust_eegphaseresid{grp, 1}(part, chan) = r.Pearson;
           
           % correlate phase of ongoing signal and RT 
           x = [[EEG_amplit_bsln{1}(chan, :)'; EEG_amplit_bsln{2}(chan, :)'].*cos([EEG_phase_bsln{1}(chan, :)'; EEG_phase_bsln{2}(chan, :)']),...
               [EEG_amplit_bsln{1}(chan, :)'; EEG_amplit_bsln{2}(chan, :)'].*sin([EEG_phase_bsln{1}(chan, :)'; EEG_phase_bsln{2}(chan, :)']), ones(length(DV), 1)];
           [coeffs_EEGphase_RT{grp, 1}(part, chan, :),~,~, ~, stats_mult_regrs{grp, 1}(part, chan, :)] = regress(DV, x);
           
        end

        % gng
        DV = [RT_incl{3}; RT_incl{4}];
        for chan = 1:size(ERPs{1}, 1) 
            IV = Res_gng(:, chan);
            [r,~,~,~,~,~] = skipped_correlation(IV,DV,0);
            coeff_robust_eegphaseresid{grp, 2}(part, chan) = r.Pearson;
            
           % correlate phase of ongoing signal and RT 
           x = [[EEG_amplit_bsln{3}(chan, :)'; EEG_amplit_bsln{4}(chan, :)'].*cos([EEG_phase_bsln{3}(chan, :)'; EEG_phase_bsln{4}(chan, :)']),...
               [EEG_amplit_bsln{3}(chan, :)'; EEG_amplit_bsln{4}(chan, :)'].*sin([EEG_phase_bsln{3}(chan, :)'; EEG_phase_bsln{4}(chan, :)']), ones(length(DV), 1)];
           [coeffs_EEGphase_RT{grp, 2}(part, chan, :),~,~, ~, stats_mult_regrs{grp, 1}(part, chan, :)] = regress(DV, x);
        end
        
        % calculate std across trials, simple RT and gng task - ERP
        % residuals after reggressing EEG phase at baseline
        erp_residuals_std{grp, 1}(part, :) = std(Res_simpleRT, [], 1); % simple RT
        erp_residuals_std{grp, 2}(part, :) = std(Res_gng, [], 1); % gng
        
        erp_residuals_avg{grp, 1}(part, :) = mean(Res_simpleRT, 1); % simple RT
        erp_residuals_avg{grp, 2}(part, :) = mean(Res_gng, 1); % gng
     
    end
end
cd('G:\ProjectAgingNeuromodulation\AuditoryResearch\EEGLAB_analysis\ERP_variability');
save coeff_robust_eegphaseresid coeff_robust_eegphaseresid % correlation coefficients RT vs ERP residuals
save stats_mult_regrs stats_mult_regrs
save coeffs_EEGphase_RT coeffs_EEGphase_RT % regression coefficients EEG bsln phase vs RT
save erp_residuals_std erp_residuals_std
save erp_residuals_avg erp_residuals_avg

%% plot ERP residuals variability
load erp_residuals_std
% plot_all_data_2tasks(data_grp1_task1, data_grp1_task2, data_grp2_task1, data_grp2_task2, y_label_text)
% chan FCz
% plot_all_data_2tasks(erp_residuals_avg{1, 1}(:, 16), erp_residuals_avg{1, 2}(:, 16), erp_residuals_avg{2, 1}(:, 16), erp_residuals_avg{2, 2}(:, 16),'CNV residuals amplitude')

plot_all_data_2tasks(erp_residuals_std{1, 1}(:, 16), erp_residuals_std{1, 2}(:, 16), erp_residuals_std{2, 1}(:, 16), erp_residuals_std{2, 2}(:, 16), 'CNV residuals SD')

% plot_all_data_onetask(data_grp1_task1, data_grp2_task1, y_label_text)
plot_all_data_onetask(erp_residuals_std{1, 2}(:, 16), erp_residuals_std{2, 2}(:, 16), 'CNV residuals SD')

% check if variability if different across groups
for task = 1:2
    [pval_std(task, :), t_orig_std(task, :), crit_t_std(task, :), est_alpha, seed_state]=mult_comp_perm_t2(erp_residuals_std{1, task},erp_residuals_std{2, task});
end


% plot  - t values
load G:\ProjectAgingNeuromodulation\AuditoryResearch\EEGLAB_analysis\chanlocs_EEGChanOnly.mat
title_txt = {'Simple RT' 'Go/no-go'};
for task = 1:2
    
    sig_t_values = zeros(1, 59);
    sig_t_values(t_orig_std(task, :) > crit_t_std(task, 2)) = 1;
    sig_t_values(t_orig_std(task, :) < crit_t_std(task, 1)) = 1;
    sig_chan_number = find(sig_t_values == 1);

    for x = 1:length(sig_chan_number)
        sig_chans_std{task}{x} = chanlocs_EEGChanOnly(sig_chan_number(x)).labels;
    end
    
    figure;
    topoplot(ones(59, 1)*.025, chanlocs_EEGChanOnly, 'electrodes', 'off', 'plotchans', sig_chan_number, 'style', 'blank',...
    'plotdisk', 'on',  'hcolor'  , 'none') ; hold on
    topoplot(t_orig_std(task, :), chanlocs_EEGChanOnly, 'electrodes', 'off'); 
    Axis.FontSize = 16; caxis([0 6]); 
    colorbar;
    colorbar('Ticks',[0, 2, 4, 6], 'FontSize', 30, 'FontWeight','normal');
    colormap(crameri('imola'));
%     title(title_txt{task}, 'FontSize', 24, 'FontWeight','normal')
%     set(get(gca,'title'),'Position',[0,-.65, 0])
end


%% multiple regression eeg phase vs RT
cd('G:\ProjectAgingNeuromodulation\AuditoryResearch\EEGLAB_analysis\ERP_variability');
load coeffs_EEGphase_RT % grp task - part, chan, coeffs
% coeffs_EEGphase_RT{grp, 1}(part, chan, :)
task_name = {'Simple RT' 'Go/no-go'};

clear pval_t1 t_orig_t1 crit_t_t1 pval_t1_all t_orig_t1_all crit_t_t1_all
for task = 1:2
    for coef = 1:2
        for grp = 1:2
            [pval_t1(grp, task, coef, :), t_orig_t1(grp, task, coef, :), crit_t_t1(grp, task, coef, :),~,~]=mult_comp_perm_t1(squeeze(coeffs_EEGphase_RT{grp, task}(:, :, coef)));
        end
        [pval_t2(task, :, coef), t_orig_t2(task, :, coef), crit_t_t2(task, :, coef),~,~] = mult_comp_perm_t2(squeeze(coeffs_EEGphase_RT{1, task}(:, :, coef)),squeeze(coeffs_EEGphase_RT{2, task}(:, :, coef)));
        [pval_t1_all(task, coef, :), t_orig_t1_all(task, coef, :), crit_t_t1_all(task, coef, :),~,~]=mult_comp_perm_t1([squeeze(coeffs_EEGphase_RT{1, task}(:, :, coef)); squeeze(coeffs_EEGphase_RT{2, task}(:, :, coef))]);
        
%         plot_data_all_electrodes(squeeze(coeffs_EEGphase_RT{1, task}(:, :, coef)), squeeze(coeffs_EEGphase_RT{2, task}(:, :, coef)), 'Regression Coeffs', ['Coef', num2str(coef), ' - ', task_name(task)])
    end
end

% coefficients not significantly different from zero! together or
% separately by group
% group comparison - max t values
max(max(abs(t_orig_t2(:, :, :))))
min(min(abs(pval_t2(:, :, :))))

% different from zero
% simple RT
max(max(abs(t_orig_t1_all(1, :, :))))
min(min(abs(pval_t1_all(1, :, :))))

% gng
% cosine
max(abs(t_orig_t1_all(2, 1, :)))
min(abs(pval_t1_all(2, 1, :)))

% gng
% sine
max(abs(t_orig_t1_all(2, 2, :)))
max((t_orig_t1_all(2, 2, :)))
min((t_orig_t1_all(2, 2, :)))
min(abs(pval_t1_all(2, 2, :)))

find(abs(pval_t1_all(2, 2, :)) < .05)


% plot  - t values - one- sample t-test with all participants coefficients
% against zero
load G:\ProjectAgingNeuromodulation\AuditoryResearch\EEGLAB_analysis\chanlocs_EEGChanOnly.mat
title_txt = {'Simple RT' 'Go/no-go'}; clear sig_chans_std
clear sig_chans_std
for task = 2%1:2
    for coef = 1:2
        sig_t_values = zeros(1, 59);
        sig_t_values(t_orig_t1_all(task, coef, :) > crit_t_t1_all(task, coef, 2)) = 1;
        sig_t_values(t_orig_t1_all(task, coef, :) < crit_t_t1_all(task, coef, 1)) = 1;
        sig_chan_number = find(sig_t_values == 1);

        for x = 1:length(sig_chan_number)
            sig_chans_std{task}{x} = chanlocs_EEGChanOnly(sig_chan_number(x)).labels;
        end

        figure;
        if ~isempty(sig_chan_number)
            topoplot(ones(59, 1)*.025, chanlocs_EEGChanOnly, 'electrodes', 'off', 'plotchans', sig_chan_number, 'style', 'blank',...
                    'plotdisk', 'on',  'hcolor'  , 'none') ; hold on
        end
        topoplot(t_orig_t1_all(task, coef, :), chanlocs_EEGChanOnly, 'electrodes', 'off'); 
        Axis.FontSize = 16; caxis([-4 4]); 
        colorbar;
        colorbar('Ticks',[-4, -2, 0, 2, 4], 'FontSize', 30, 'FontWeight','normal');
        colormap(crameri('imola'));
    %     title(title_txt{task}, 'FontSize', 24, 'FontWeight','normal')
    %     set(get(gca,'title'),'Position',[0,-.65, 0])
    end
end

%% each group separate
clear sig_chans_std
for grp = 1:2
    for task = 2%1:2
        for coef = 2%1:2
            sig_t_values = zeros(1, 59);
            sig_t_values(t_orig_t1(grp, task, coef, :) > crit_t_t1(grp, task, coef, 2)) = 1;
            sig_t_values(t_orig_t1(grp, task, coef, :) < crit_t_t1(grp, task, coef, 1)) = 1;
            sig_chan_number = find(sig_t_values == 1);

            for x = 1:length(sig_chan_number)
                sig_chans_std{grp, task}{x} = chanlocs_EEGChanOnly(sig_chan_number(x)).labels;
            end

            figure;
            if ~isempty(sig_chan_number)
                topoplot(ones(59, 1)*.025, chanlocs_EEGChanOnly, 'electrodes', 'off', 'plotchans', sig_chan_number, 'style', 'blank',...
                        'plotdisk', 'on',  'hcolor'  , 'none') ; hold on
            end
            topoplot(t_orig_t1(grp, task, coef, :), chanlocs_EEGChanOnly, 'electrodes', 'off'); 
            Axis.FontSize = 16; caxis([-4 4]); 
            colorbar;
            colorbar('Ticks',[-4, -2, 0, 2, 4], 'FontSize', 30, 'FontWeight','normal');
            colormap(crameri('imola'));
        %     title(title_txt{task}, 'FontSize', 24, 'FontWeight','normal')
        %     set(get(gca,'title'),'Position',[0,-.65, 0])
        end
    end
end

%% group comparisons
clear sig_chans_std
for task = 2%1:2
    for coef = 1:2
        sig_t_values = zeros(1, 59);
        sig_t_values(t_orig_t2(task, :, coef) > crit_t_t2(task, 2, coef)) = 1;
        sig_t_values(t_orig_t2(task, :, coef) < crit_t_t2(task, 1, coef)) = 1;
        sig_chan_number = find(sig_t_values == 1);

        for x = 1:length(sig_chan_number)
            sig_chans_std{task}{x} = chanlocs_EEGChanOnly(sig_chan_number(x)).labels;
        end

        figure;
        if ~isempty(sig_chan_number)
            topoplot(ones(59, 1)*.025, chanlocs_EEGChanOnly, 'electrodes', 'off', 'plotchans', sig_chan_number, 'style', 'blank',...
                    'plotdisk', 'on',  'hcolor'  , 'none') ; hold on
        end
        topoplot(squeeze(t_orig_t2(task, :, coef)), chanlocs_EEGChanOnly, 'electrodes', 'off'); 
        Axis.FontSize = 16; caxis([-2 2]); 
        colorbar;
        colorbar('Ticks',[-2, -1, 0, 1, 2], 'FontSize', 30, 'FontWeight','normal');
        colormap(crameri('imola'));
    %     title(title_txt{task}, 'FontSize', 24, 'FontWeight','normal')
    %     set(get(gca,'title'),'Position',[0,-.65, 0])
    end
end

%% compare coefficients without adjustment with adjustment
% load coefficients correlation CNV vs RT 
load coeff_robust_chan; % calculated in :\ProjectAgingNeuromodulation\AuditoryResearch\EEGLAB_analysis\ERP_variability\RTvsCueLockERP_per_task.m
load coeff_robust_eegphaseresid; % correlation coeffieint CNV adjusted for baseline fluctuations vs RT
clear pval_t1 t_orig_t1 crit_t_t1
for task = 1:2
    for grp = 1:2
        [pval_t1(grp, task, :), t_orig_t1(grp, task, :), crit_t_t1(grp, task, :),~,~]=mult_comp_perm_t1(coeff_robust_eegphaseresid{grp, task}-coeff_robust_chan{grp, task});
    end
end

% testing will all participants together
for task = 1:2
    [pval_t1_b4after(task, :), t_orig_t1_b4after(task, :), crit_t_t1_b4after(task, :),~,~]=mult_comp_perm_t1([coeff_robust_eegphaseresid{1, task}; coeff_robust_eegphaseresid{2, task}]-[coeff_robust_chan{1, task}; coeff_robust_chan{2, task}]);
end

% plot t-values from one sample t-test both groups together
load G:\ProjectAgingNeuromodulation\AuditoryResearch\EEGLAB_analysis\chanlocs_EEGChanOnly.mat
title_txt = {'Simple RT' 'Go/no-go'};%cmap = crameri('batlow');
for task = 1:2
    
    sig_t_values = zeros(1, 59);
    sig_t_values(t_orig_t1_b4after(task, :) > crit_t_t1_b4after(task, 2)) = 1;
    sig_t_values(t_orig_t1_b4after(task, :) < crit_t_t1_b4after(task, 1)) = 1;
    sig_chan_number = find(sig_t_values == 1);

    for x = 1:length(sig_chan_number)
        sig_chans_all{task}{x} = chanlocs_EEGChanOnly(sig_chan_number(x)).labels;
    end
    
    figure; 
    if ~isempty(sig_chan_number)
        topoplot(ones(59, 1)*.025, chanlocs_EEGChanOnly, 'electrodes', 'off', 'plotchans', sig_chan_number, 'style', 'blank',...
                'plotdisk', 'on',  'hcolor'  , 'none') ; hold on
    end
    topoplot(t_orig_t1_b4after(task, :), chanlocs_EEGChanOnly, 'electrodes', 'off'); 
    caxis([0 5]); %c.Axis.FontSize = 16;
    colorbar;
    colorbar('Ticks',[0, 2, 4], 'FontSize', 30, 'FontWeight','normal');
    colormap(crameri('imola')); % needs colour maps from http://www.fabiocrameri.ch/colourmaps.php
    title(title_txt{task}, 'FontSize', 30, 'FontWeight','normal')
    set(get(gca,'title'),'Position',[0,-.65, 0])

% 
%     % plot average correlation coefficients with significant electrodes
%     % highlighted
%     figure; 
%     if ~isempty(sig_chan_number)
%         topoplot(ones(59, 1)*.025, chanlocs_EEGChanOnly, 'electrodes', 'off', 'plotchans', sig_chan_number, 'style', 'blank',...
%                 'plotdisk', 'on',  'hcolor'  , 'none') ; hold on
%     end
%     topoplot(mean([coeff_robust_eegphaseresid{1, task}; coeff_robust_eegphaseresid{2, task}], 1), chanlocs_EEGChanOnly, 'electrodes', 'off'); 
%     caxis([0 .1]); %c.Axis.FontSize = 16;
%     colorbar;
%     colorbar('Ticks',[0, .05, .1], 'FontSize', 30, 'FontWeight','normal');
%     colormap(crameri('imola')); % needs colour maps from http://www.fabiocrameri.ch/colourmaps.php

end

%% stats_mult_regrs{grp, 2}(part, chan, :

mean(stats_mult_regrs{1, 1}(:, :, 3), 1)


%% plot C5 plot_all_data_2groups(data_grp1, data_grp2, y_label_text, title_text)
% coeff_robust_erpresid_chan {grp, task}(part, chan)
load coeff_robust_eegphaseresid; % correlation coefficients RT vs ERP residuals
load G:\ProjectAgingNeuromodulation\AuditoryResearch\EEGLAB_analysis\chanlocs_EEGChanOnly.mat
title_txt = {'simpleRT', 'go/no-go'};
for c = 1:size(chanlocs_EEGChanOnly, 1)
    if strcmp(chanlocs_EEGChanOnly(c).labels, 'C5')
        chan = c;
    end
end
% plot_all_data_2tasks(data_grp1_task1, data_grp1_task2, data_grp2_task1, data_grp2_task2, y_label_text)
plot_all_data_2tasks(coeff_robust_eegphaseresid{1, 1}(:, chan), coeff_robust_eegphaseresid{1, 2}(:, chan),...
    coeff_robust_eegphaseresid{2, 1}(:, chan), coeff_robust_eegphaseresid{2, 2}(:, chan),'Correlation \itr')

% plot_all_data_onetask(data_grp1_task1, data_grp2_task1, y_label_text)
plot_all_data_onetask(coeff_robust_eegphaseresid{1, 2}(:, chan), coeff_robust_eegphaseresid{2, 2}(:, chan),'Correlation \itr')


%% stats using permutation method
load coeff_robust_eegphaseresid % correlation coefficients RT vs ERP residuals
clear pval_t1 t_orig_t1 crit_t_t1 pval_t1_all t_orig_t1_all crit_t_t1_all pval_t2 t_orig_t2 crit_t_t2
for task = 1:2
    for grp = 1:2
        [pval_t1(grp, task, :), t_orig_t1(grp, task, :), crit_t_t1(grp, task, :), est_alpha, seed_state]=mult_comp_perm_t1(coeff_robust_eegphaseresid{grp, task});
    end
    [pval_t2(task, :), t_orig_t2(task, :), crit_t_t2(task, :), est_alpha, seed_state] = mult_comp_perm_t2(coeff_robust_eegphaseresid{1, task},coeff_robust_eegphaseresid{2, task});
    [pval_t1_all(task, :), t_orig_t1_all(task, :), crit_t_t1_all(task, :), est_alpha, seed_state]=mult_comp_perm_t1([coeff_robust_eegphaseresid{1, task};coeff_robust_eegphaseresid{2, task}]);
end

% plot t-values from one sample t-test both groups together
load G:\ProjectAgingNeuromodulation\AuditoryResearch\EEGLAB_analysis\chanlocs_EEGChanOnly.mat
title_txt = {'Simple RT' 'Go/no-go'};%cmap = crameri('batlow');
for task = 1:2
    
    sig_t_values = zeros(1, 59);
    sig_t_values(t_orig_t1_all(task, :) > crit_t_t1_all(task, 2)) = 1;
    sig_t_values(t_orig_t1_all(task, :) < crit_t_t1_all(task, 1)) = 1;
    sig_chan_number = find(sig_t_values == 1);

    for x = 1:length(sig_chan_number)
        sig_chans_all{task}{x} = chanlocs_EEGChanOnly(sig_chan_number(x)).labels;
    end
    
%     figure; 
%     if ~isempty(sig_chan_number)
%         topoplot(ones(59, 1)*.025, chanlocs_EEGChanOnly, 'electrodes', 'off', 'plotchans', sig_chan_number, 'style', 'blank',...
%                 'plotdisk', 'on',  'hcolor'  , 'none') ; hold on
%     end
%     topoplot(t_orig_t1_all(task, :), chanlocs_EEGChanOnly, 'electrodes', 'off'); 
%     caxis([0 5]); %c.Axis.FontSize = 16;
%     colorbar;
%     colorbar('Ticks',[0, 2, 4], 'FontSize', 30, 'FontWeight','normal');
%     colormap(crameri('imola')); % needs colour maps from http://www.fabiocrameri.ch/colourmaps.php
%     title(title_txt{task}, 'FontSize', 30, 'FontWeight','normal')
%     title('bamako', 'FontSize', 30, 'FontWeight','normal')
%     set(get(gca,'title'),'Position',[0,-.65, 0])


    % plot average correlation coefficients with significant electrodes
    % highlighted
    figure; 
    if ~isempty(sig_chan_number)
        topoplot(ones(59, 1)*.025, chanlocs_EEGChanOnly, 'electrodes', 'off', 'plotchans', sig_chan_number, 'style', 'blank',...
                'plotdisk', 'on',  'hcolor'  , 'none') ; hold on
    end
    topoplot(mean([coeff_robust_eegphaseresid{1, task}; coeff_robust_eegphaseresid{2, task}], 1), chanlocs_EEGChanOnly, 'electrodes', 'off'); 
    caxis([0 .1]); %c.Axis.FontSize = 16;
    colorbar;
    colorbar('Ticks',[0, .05, .1], 'FontSize', 30, 'FontWeight','normal');
    colormap(crameri('imola')); % needs colour maps from http://www.fabiocrameri.ch/colourmaps.php

end

%% plot electrodes where correlation r different from zero - t values
clear sig_chans
load G:\ProjectAgingNeuromodulation\AuditoryResearch\EEGLAB_analysis\chanlocs_EEGChanOnly.mat
title_txt = {'Young - simple RT' 'Older - simple RT'; 'Young - go/no-go' 'Older - go/no-go'};
for grp = 1:2
    for task = 1:2

        sig_t_values = zeros(1, 59);
        sig_t_values(t_orig_t1(grp, task, :) > crit_t_t1(grp, task, 2)) = 1;
        sig_t_values(t_orig_t1(grp, task, :) < crit_t_t1(grp, task, 1)) = 1;
        sig_chan_number = find(sig_t_values == 1);
       

        for x = 1:length(sig_chan_number)
            sig_chans{grp, task}{x} = chanlocs_EEGChanOnly(sig_chan_number(x)).labels;
        end

        
        figure;
        if ~isempty(sig_chan_number)
            topoplot(ones(59, 1)*.025, chanlocs_EEGChanOnly, 'electrodes', 'off', 'plotchans', sig_chan_number, 'style', 'blank',...
                'plotdisk', 'on',  'hcolor'  , 'none') ; hold on
        end
        topoplot(t_orig_t1(grp, task, :), chanlocs_EEGChanOnly, 'electrodes', 'off'); 
        caxis([0 5]); %c.Axis.FontSize = 16;
        colorbar;
        colorbar('Ticks',[0, 1, 2, 3, 4, 5], 'FontSize', 18, 'FontWeight','normal');
        colormap(crameri('imola')); % needs colour maps from http://www.fabiocrameri.ch/colourmaps.php
        title(title_txt{task, grp}, 'FontSize', 24, 'FontWeight','normal')
        set(get(gca,'title'),'Position',[0,-.6, 0])
%         text(5, 0.4, title_txt{task, grp})
        
    end
end


%% function plot data 2 groups 1 task
function plot_all_data_2groups(data_grp1, data_grp2, y_label_text, title_text)
       figure;
    % plot data for group 1
        yMean=nanmean(data_grp1);
    y_se = std(data_grp1)/sqrt(length(data_grp1));
    
        %plot the mean+-SEM box
        %   RECTANGLE('Position',pos) creates a rectangle in 2-D coordinates.
%   Specify pos as a four-element vector of the form [x y w h] in data
%   units. The x and y elements determine the location and the w and h
%   elements determine the size. The function plots into the current axes
%   without clearing existing content from the axes.
    box on
    rectangle('Position',[1-0.3,yMean-y_se, 0.6, 2*y_se ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1);
    hold on
    for y=1:length(data_grp1)
        plot(1+rand*0.2-0.1, data_grp1(y),'-o', 'color', [.8 .8 .8], ...
            'MarkerFaceColor',[.8 .8 .8], 'MarkerEdgeColor','k','MarkerSize',8, 'LineWidth', 1);
        hold on;
    end
    %plot line at zero    
    plot([0 4],[0 0],'--k','LineWidth', 1);
     %plot the mean line    
    plot([1-0.3 1+0.3],[yMean yMean] ,'Color','k','LineWidth',5);
   

    %% group 2
    yMean=nanmean(data_grp2);
    y_se = std(data_grp2)/sqrt(length(data_grp2));
   rectangle('Position',[2-0.3,yMean-y_se, 0.6, 2*y_se ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1)
   
    for y=1:length(data_grp2)
        plot(2+rand*0.2-0.1, [data_grp2(y)] ,'-o', 'color', [1 .8 .8], ...
            'MarkerFaceColor',[1 .8 .8], 'MarkerEdgeColor','k','MarkerSize',8, 'LineWidth', 1);
        hold on;  
    end

     %plot the mean line
    plot([2-0.3 2+0.3],[yMean yMean] ,'Color','k','LineWidth',5);
    

    % axes('XColor','none');
    hold off;
    axis([0 3 -inf inf]);
    ax = gca;
    c = ax.Color;
    ax.FontSize = 28;
    ax.FontName = 'Arial';
    ax.Color = 'none';
%     ax.XTickLabel= [];
    ax.XTickLabel= [{'' 'Young' 'Older' ''}];
%     xticks([1 2])
    ylabel(y_label_text, 'FontSize', 32, 'FontWeight','normal')
    title(title_text, 'FontSize', 32, 'FontWeight','normal')
    
%     x0=10;
%     y0=10;
%     width=400;
%     height=400;
%     set(gcf,'position',[x0,y0,width,height])
end



function plot_data_all_electrodes(data_young, data_older, yaxis_title, title_txt)

    % plot 
    figure; 
    plot(.8:58.8, data_young, 'o', 'MarkerFaceColor',[.8 .8 .8], 'MarkerEdgeColor','k', 'MarkerSize', 5); hold on;
    plot(1.2:59.2, data_older, 'o', 'MarkerFaceColor',[1 .8 .8], 'MarkerEdgeColor','r','MarkerSize', 5); hold on
    mean_data = mean(data_young, 1, 'omitnan'); se_data = std(data_young, [], 1, 'omitnan')/sqrt(size(data_young, 1));
    plot(1:59, mean_data', '-', 'color', 'k', 'LineWidth', 2); hold on;
    jbfill(1:59, mean_data+se_data, mean_data-se_data,'k','k', 0.1); hold on;

    mean_data = mean(data_older, 1, 'omitnan'); se_data = std(data_older, [], 1, 'omitnan')/sqrt(size(data_older, 1));
    plot(1:59,  mean_data', '-', 'color', 'r', 'LineWidth', 2, 'MarkerEdgeColor', 'r',...
        'MarkerSize', 10); hold on;
    jbfill(1:59, mean_data+se_data, mean_data-se_data,'r','r', 0.1); hold on;
    
    % plot zero line
    plot(0:60, zeros(1,61), '--k'); hold on
    

    axis([0 61 -inf inf]);
    ax = gca; c = ax.Color; ax.FontSize = 12; ax.FontName = 'Arial'; ax.Color = 'none';
%     set(gca, 'YScale', 'log')
%     ax.XTickLabel=x_axis(1:59);
%     xticks(1:59)
    xlabel('Electrodes', 'FontSize', 18, 'FontWeight','normal')
    ylabel(yaxis_title, 'FontSize', 18, 'FontWeight','normal')
    title(title_txt, 'FontSize', 18, 'FontWeight','normal')
    x0=0; y0=0; width=1600; height=300; set(gcf,'position',[x0,y0,width,height])
end


%% function to interpolate missing channels - Marco Sim�es   
% interpolates and reorders channels so they are in right order!
    function [EEG] = interpol( EEG, chanlocs )
        % interpolation
        if nargin < 2
            load('G:\ProjectAgingNeuromodulation\AuditoryResearch\EEGLAB_analysis\chanlocs.mat');
        end

        chans_eeg = [];
        for i=1:length(EEG.chanlocs)
            chans_eeg = [ chans_eeg {EEG.chanlocs(i).labels} ];
        end

        idxs = [];
        for i=1:length(chanlocs)
            index = find(ismember(chans_eeg, chanlocs(i).labels) == 1, 1);
            if isempty(index)
                idxs = [idxs i];
            end
        end

        EEG = pop_interp(EEG, chanlocs(idxs), 'spherical');

        % reorder
        chans_eeg = [];
        for c=1:length(EEG.chanlocs)
            chans_eeg = [ chans_eeg {EEG.chanlocs(c).labels} ];
        end

        idxs = [];
        for c=1:length(chanlocs)
            index = find(ismember(chans_eeg, chanlocs(c).labels) == 1, 1);
            idxs = [idxs index];
        end

        %if length(idxs) == 58

           EEG.data = EEG.data(idxs,:,:);
           EEG.chanlocs = EEG.chanlocs(idxs);

           indcomps = [];
           for compidx = 1:length(EEG.icachansind)
               indcomps = [indcomps find(EEG.icachansind(compidx) == idxs)];
           end
           EEG.icachansind = indcomps;

   % end
    end

    function plot_quintiles(data, title_text)

    Mean1= squeeze(mean(data(:,1,:), 1));
    Mean2= squeeze(mean(data(:,2,:), 1));
    Mean3= squeeze(mean(data(:,3,:), 1));
    Mean4= squeeze(mean(data(:,4,:), 1));
    Mean5= squeeze(mean(data(:,5,:), 1));

    SE1=(squeeze(std(data(:,1,:), 0, 1))/sqrt(size(data, 1)));
    SE2=(squeeze(std(data(:,2,:), 0, 1))/sqrt(size(data, 1)));
    SE3=(squeeze(std(data(:,3,:), 0, 1))/sqrt(size(data, 1)));
    SE4=(squeeze(std(data(:,4,:), 0, 1))/sqrt(size(data, 1)));
    SE5=(squeeze(std(data(:,5,:), 0, 1))/sqrt(size(data, 1)));

    colormap cool;%colormap summer;
    cmap = colormap;

    figure;
    xaxis = -.199:1/500:2;
    
    for x = 1.001:1/500:1.500 % grey background between 1000 amd 1500ms after ceu-onset
        plot([x x],[-12.8 1.8], 'color', [.8 .8 .8] ); hold on
    end
    % zero line
    plot(xaxis, zeros(length(xaxis)), 'k:');
    hold on
    plot( xaxis', Mean1, 'color', cmap(10,:), 'linewidth', 2);
    hold on
    jbfill(xaxis,(Mean1+SE1)',(Mean1-SE1)', cmap(10,:), cmap(10,:), 1, 0.2)
    hold on
    plot( xaxis, Mean2, 'color', cmap(20,:), 'linewidth', 2);
    hold on
    jbfill(xaxis,(Mean2+SE2)',(Mean2-SE2)', cmap(20,:), cmap(20,:), 1, 0.2)
    hold on
    plot( xaxis, Mean3, 'color', cmap(30,:), 'linewidth', 2);
    hold on
    jbfill(xaxis,(Mean3+SE3)',(Mean3-SE3)', cmap(30,:), cmap(30,:), 1, 0.2)
    hold on
    plot( xaxis, Mean4, 'color', cmap(40,:), 'linewidth', 2);
    hold on
    jbfill(xaxis,(Mean4+SE4)',(Mean4-SE4)', cmap(40,:), cmap(40,:), 1, 0.2)
    hold on
    plot( xaxis, Mean5, 'color', cmap(50,:), 'linewidth', 2);
    hold on
    jbfill(xaxis,(Mean5+SE5)',(Mean5-SE5)', cmap(50,:), cmap(50,:), 1, 0.2)
    hold on
    % plot(xaxis, zeros(1, 840), ':k')
    hold off
    axis([0 2 -13 2]);
    % title('GNG', 'FontSize', 24, 'FontWeight','bold')
    % legend('RT1', 'RT2', 'RT3', 'RT4', 'RT5', 'location', 'northwest')
    ax = gca;
    ax.FontSize = 24;
    ax.FontName = 'Arial';
    ax.Color = 'none';
    xlabel('Time (s)', 'FontSize', 32, 'FontWeight','normal')
    ylabel('Amplitude (\muV)', 'FontSize', 32, 'FontWeight','normal')
    title(title_text, 'FontSize', 32, 'FontWeight','normal');
    
    end

    

    %% function to plot all data points 2 tasks 2 groups
function plot_all_data_2tasks(data_grp1_task1, data_grp1_task2, data_grp2_task1, data_grp2_task2, y_label_text)

    % plot data for young group - simple RT and go/nogo task
    figure; box off; hold on
    
    % plot data for group 1
    yMean1=nanmean(data_grp1_task1); yMean2=nanmean(data_grp1_task2);
    y_se1 = nanstd(data_grp1_task1)/sqrt(length(data_grp1_task1)); y_se2 = nanstd(data_grp1_task2)/sqrt(length(data_grp1_task2));
    
    %plot the mean+-SEM box
    %   RECTANGLE('Position',pos) creates a rectangle in 2-D coordinates.
    %   Specify pos as a four-element vector of the form [x y w h] in data
    %   units. The x and y elements determine the location and the w and h
    %   elements determine the size. The function plots into the current axes
    %   without clearing existing content from the axes.
    rectangle('Position',[1-0.3,yMean1-y_se1, 0.6, 2*y_se1 ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1);
    rectangle('Position',[2-0.3,yMean2-y_se2, 0.6, 2*y_se2 ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1);
    
    for y=1:length(data_grp1_task1)
        plot([1 2]+rand*0.2-0.1, [data_grp1_task1(y) data_grp1_task2(y)] ,'-o', 'color', [.8 .8 .8], ...
            'MarkerFaceColor',[.8 .8 .8], 'MarkerEdgeColor','k','MarkerSize',8, 'LineWidth', 1);
        hold on;
    end

    %plot the mean line
    plot([1 2 ],[yMean1 yMean2] ,'Color','k','LineWidth',1.5);
    plot([1-0.3 1+0.3],[yMean1 yMean1] ,'Color','k','LineWidth',5);
    plot([2-0.3 2+0.3],[yMean2 yMean2] ,'Color','k','LineWidth',5);
    
    
    % group 2
        yMean1=nanmean(data_grp2_task1); yMean2=nanmean(data_grp2_task2);
    y_se1 = nanstd(data_grp2_task1)/sqrt(length(data_grp2_task1)); y_se2 = nanstd(data_grp2_task2)/sqrt(length(data_grp2_task2));
    
    %plot the mean+-SEM box
    %   RECTANGLE('Position',pos) creates a rectangle in 2-D coordinates.
    %   Specify pos as a four-element vector of the form [x y w h] in data
    %   units. The x and y elements determine the location and the w and h
    %   elements determine the size. The function plots into the current axes
    %   without clearing existing content from the axes.
    rectangle('Position',[4-0.3,yMean1-y_se1, 0.6, 2*y_se1 ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1);
    rectangle('Position',[5-0.3,yMean2-y_se2, 0.6, 2*y_se2 ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1);
    
    for y=1:length(data_grp2_task1)
        plot([4 5]+rand*0.2-0.1, [data_grp2_task1(y) data_grp2_task2(y)] ,'-o', 'color', [1 .8 .8], ...
            'MarkerFaceColor',[1 .8 .8], 'MarkerEdgeColor','k','MarkerSize',8, 'LineWidth', 1);
        hold on;  
    end

     %plot the mean line
    plot([4 5],[yMean1 yMean2] ,'Color','k','LineWidth',1.5);
    plot([4-0.3 4+0.3],[yMean1 yMean1] ,'Color','k','LineWidth',5);
    plot([5-0.3 5+0.3],[yMean2 yMean2] ,'Color','k','LineWidth',5);
    
    % plot line on zero
    plot([0 6], zeros(2, 1), '--k')
    

    % axes('XColor','none');
    hold off;
    axis([0 6 -inf inf]);
    ax = gca;
    ax.LineWidth = 2.5; 
    ax.FontSize = 24;
    ax.FontName = 'Arial';
    ax.Color = 'none';
    ax.XTickLabel=[1 2 1 2];
    xticks([1 2 4 5])
    ylabel(y_label_text, 'FontSize',32, 'FontWeight','normal')
    
%     x0=10;
%     y0=10;
%     width=400;
%     height=400;
%     set(gcf,'position',[x0,y0,width,height])
end



function plot_all_data_onetask(data_grp1_task1, data_grp2_task1, y_label_text)

    % plot data for young group - go/nogo task
    figure; box off; hold on
    
    plot([0 3], [0 0], '--k'); % line at zero
    hold on
    % plot data for group 1
    yMean1=nanmean(data_grp1_task1);
    y_se1 = std(data_grp1_task1)/sqrt(length(data_grp1_task1));
    
    %plot the mean+-SEM box
    %   RECTANGLE('Position',pos) creates a rectangle in 2-D coordinates.
    %   Specify pos as a four-element vector of the form [x y w h] in data
    %   units. The x and y elements determine the location and the w and h
    %   elements determine the size. The function plots into the current axes
    %   without clearing existing content from the axes.
    rectangle('Position',[1-0.3,yMean1-y_se1, 0.6, 2*y_se1 ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1);
    
    for y=1:length(data_grp1_task1)
        plot(1+rand*0.2-0.1, data_grp1_task1(y),'-o', 'color', [.8 .8 .8], ...
            'MarkerFaceColor',[.8 .8 .8], 'MarkerEdgeColor','k','MarkerSize',12, 'LineWidth', 1.5);
        hold on;
    end

    %plot the mean line
    plot(1,yMean1,'Color','k','LineWidth',1.5);
    plot([1-0.3 1+0.3],[yMean1 yMean1] ,'Color','k','LineWidth',5);
    
    
    %% group 2
        yMean1=nanmean(data_grp2_task1);
    y_se1 = std(data_grp2_task1)/sqrt(length(data_grp2_task1));
    
    %plot the mean+-SEM box
    %   RECTANGLE('Position',pos) creates a rectangle in 2-D coordinates.
    %   Specify pos as a four-element vector of the form [x y w h] in data
    %   units. The x and y elements determine the location and the w and h
    %   elements determine the size. The function plots into the current axes
    %   without clearing existing content from the axes.
    rectangle('Position',[2-0.3,yMean1-y_se1, 0.6, 2*y_se1 ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1);
    
    for y=1:length(data_grp2_task1)
        plot(2+rand*0.2-0.1, data_grp2_task1(y),'-o', 'color', [1 .5 .5], ...
            'MarkerFaceColor',[1 .5 .5], 'MarkerEdgeColor','k','MarkerSize',12, 'LineWidth', 1.5);
        hold on;  
    end

     %plot the mean line
    plot(2,yMean1 ,'Color','k','LineWidth',1.5);
    plot([2-0.3 2+0.3],[yMean1 yMean1] ,'Color','k','LineWidth',5);

    % axes('XColor','none');
    hold off;
    axis([0 3 -inf inf]);
    ax = gca;
    ax.LineWidth = 2.5; 
    ax.YAxis.FontSize = 18;
    ax.XAxis.FontSize = 28;
    ax.FontName = 'Arial';
    ax.Color = 'none';
    ax.XTickLabel= {'Young' 'Older'};
    xticks([1 2])
    ylabel(y_label_text, 'FontSize', 28, 'FontWeight','normal')
    
%     x0=10;
%     y0=10;
%     width=400;
%     height=400;
%     set(gcf,'position',[x0,y0,width,height])
end

