save("featuretable.mat", "FeatureTable1");
T = FeatureTable1;
y = categorical(T.Flankwear_Label);

nonFeat = intersect(T.Properties.VariableNames, {'Flankwear_Label','Row_Label'});
X = removevars(T, nonFeat);
names = X.Properties.VariableNames;

% --- ANOVA ranking ---
p = nan(1,numel(names));
for k = 1:numel(names)
    x = X.(names{k});
    if ~isnumeric(x) || all(isnan(x)) || numel(unique(x(~isnan(x)))) < 2
        p(k) = 1;
    else
        p(k) = anova1(x, y, 'off');
    end
end
score = -log10(p);

% Sort best -> worst
[scoreSorted, order] = sort(score, 'descend');
namesSorted = names(order);

% --- Correlation-aware selection that keeps best-ranked features ---
thr = 0.80;        % correlation threshold
targetN = 40;      % how many you want to end up with (adjust)
keptNames = {};

for i = 1:numel(namesSorted)
    cand = namesSorted{i};
    xCand = X.(cand);

    % Compare candidate against all already-kept features
    tooSimilar = false;
    for j = 1:numel(keptNames)
        xKeep = X.(keptNames{j});
        r = corr(xCand, xKeep, 'Rows','pairwise');   % handles NaNs
        if ~isnan(r) && abs(r) >= thr
            tooSimilar = true;
            break
        end
    end

    if ~tooSimilar
        keptNames{end+1} = cand; %#ok<AGROW>
        if numel(keptNames) >= targetN
            break
        end
    end
end

SelectedTable = T(:, [nonFeat, keptNames]);


disp(keptNames(1:min(10,end))');
disp("Selected features (In SelectedTable): " + numel(keptNames));

SelectedTable.row_label = NaN(height(SelectedTable),1);
SelectedTable.row_label(1:height(T_segments)) = T_segments.Row_Label;

