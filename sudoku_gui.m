function sudoku_gui()
close all
clc

defaultPuzzle = [
    4 5 0 0 0 0 0 0 0;
    0 0 2 0 7 0 6 3 0;
    0 0 0 0 0 0 0 2 8;
    0 0 0 9 5 0 0 0 0;
    0 8 6 0 0 0 2 0 0;
    0 2 0 6 0 0 7 5 0;
    0 0 0 0 0 0 4 7 6;
    0 7 0 0 4 5 0 0 0;
    0 0 8 0 0 9 0 0 0
    ];

% defaultPuzzle = [
%     0 0 0 0 0 6 0 0 0;
%     0 5 9 0 0 0 0 0 8;
%     2 0 0 0 0 8 0 0 0;
%     0 4 5 0 0 0 0 0 0;
%     0 0 3 0 0 0 0 0 0;
%     0 0 6 0 0 3 0 5 4;
%     0 0 0 3 2 5 0 0 6;
%     0 0 0 0 0 0 0 0 0;
%     0 0 0 0 0 0 0 0 0;
%     ];

f = uifigure('Position', [100, 100, 600, 730], 'Name', 'Sudoku Solver');
mainPanel = uipanel(f, 'Position', [50, 140, 500, 500], 'BorderType', 'none');
gridPanel = uigridlayout(mainPanel, [11, 11]);

rowSizes = repmat({48}, 1, 11);
colSizes = repmat({48}, 1, 11);
rowSizes([4,8]) = {10};
colSizes([4,8]) = {10};

gridPanel.RowHeight = rowSizes;
gridPanel.ColumnWidth = colSizes;
gridPanel.Padding = [0 0 0 0];
gridPanel.RowSpacing = 0;
gridPanel.ColumnSpacing = 0;

sudokuCells = cell(9, 9);

idxMap = [1,2,3,5,6,7,9,10,11];

for i = 1:9
    for j = 1:9
        sudokuCells{i,j} = uieditfield(gridPanel, 'numeric', ...
            'Value', 0, ...
            'FontSize', 18, ...
            'HorizontalAlignment', 'center', ...
            'Limits', [0 9], ...
            'RoundFractionalValues', true);

        sudokuCells{i,j}.Layout.Row = idxMap(i);
        sudokuCells{i,j}.Layout.Column = idxMap(j);

        if mod(floor((i-1)/3) + floor((j-1)/3), 2) == 0
            sudokuCells{i,j}.BackgroundColor = [1, 1, 1];
        else
            sudokuCells{i,j}.BackgroundColor = [0.95, 0.95, 0.95];
        end

        sudokuCells{i,j}.ValueChangedFcn = @(src, event) validateInput(src);
    end
end

labelWidth = 500;
labelHeight = 100;
centerX = (f.Position(3) - labelWidth) / 2;

statusLabel = uilabel(f, 'Text', '', 'FontSize', 14, ...
    'Position', [centerX - 25, 80, labelWidth, labelHeight], ...
    'HorizontalAlignment', 'center');

buttonWidth = 100;
buttonHeight = 40;
buttonSpacing = 35;
totalButtonWidth = 3 * buttonWidth + 2 * buttonSpacing;
centerX = (f.Position(3) - buttonWidth) / 2 - 25;
startY = 20;

% Solve button (center)
solveButton = uibutton(f, 'push', 'Text', 'Solve', ...
    'Position', [centerX, startY, buttonWidth, buttonHeight], ...
    'ButtonPushedFcn', @(btn, event) solveAndDisplay(sudokuCells, statusLabel), ...
    'FontSize', 14, 'BackgroundColor', [0.1, 0.6, 0.1], 'FontColor', 'white');

% Default button (left of Solve)
defaultButton = uibutton(f, 'push', 'Text', 'Given Set', ...
    'Position', [centerX - buttonWidth - buttonSpacing, startY, buttonWidth, buttonHeight], ...
    'ButtonPushedFcn', @(btn, event) loadDefaultPuzzle(sudokuCells, defaultPuzzle, statusLabel), ...
    'FontSize', 14, 'BackgroundColor', [0.1, 0.1, 0.6], 'FontColor', 'white');

% Clear button (right of Solve)
clearButton = uibutton(f, 'push', 'Text', 'Clear', ...
    'Position', [centerX + buttonWidth + buttonSpacing, startY, buttonWidth, buttonHeight], ...
    'ButtonPushedFcn', @(btn, event) clearBoard(sudokuCells, statusLabel), ...
    'FontSize', 14, 'BackgroundColor', [0.6, 0.1, 0.1], 'FontColor', 'white');


    function validateInput(src)
        if src.Value < 1 || src.Value > 9
            src.Value = 0;
        end
    end

    function solveAndDisplay(sudokuCells, statusLabel)
        initialGrid = zeros(9, 9);
        userInputMask = false(9, 9);

        for i = 1:9
            for j = 1:9
                val = sudokuCells{i,j}.Value;
                initialGrid(i,j) = val;
                if val ~= 0
                    userInputMask(i,j) = true;
                end
            end
        end

        drawnow;
        statusLabel.Text = 'Solving... Please wait...';
        drawnow;

        [solvedGrid, steps, restarts] = simulatedAnnealingSudoku(initialGrid, statusLabel);

        for i = 1:9
            for j = 1:9
                sudokuCells{i,j}.Value = solvedGrid(i,j);
                if userInputMask(i,j)
                    sudokuCells{i,j}.FontWeight = 'bold';
                    sudokuCells{i,j}.FontAngle = 'normal';
                else
                    sudokuCells{i,j}.FontWeight = 'normal';
                    sudokuCells{i,j}.FontAngle = 'italic';
                end
            end
        end

        if all(solvedGrid(:) == initialGrid(:))
            statusLabel.Text = 'Could not solve the puzzle after max steps.';
            uialert(f, 'The solver could not complete the puzzle. Please check for ambiguity or insufficient input.', ...
                'Unsolved', 'Icon', 'warning');
        else
            statusLabel.Text = sprintf('Solved in %d steps with %d restarts.', steps, restarts);
        end
    end

    function clearBoard(sudokuCells, statusLabel)
        for i = 1:9
            for j = 1:9
                sudokuCells{i,j}.Value = 0;
                sudokuCells{i,j}.FontWeight = 'normal';
                sudokuCells{i,j}.FontAngle = 'normal';

                if mod(floor((i-1)/3) + floor((j-1)/3), 2) == 0
                    sudokuCells{i,j}.BackgroundColor = [1, 1, 1];
                else
                    sudokuCells{i,j}.BackgroundColor = [0.95, 0.95, 0.95];
                end
            end
        end
        statusLabel.Text = '';
    end
end


%% Main Function
function [solved, step, restartCount] = simulatedAnnealingSudoku(puzzle, statusLabel)
fixed = puzzle ~= 0;
current = random_fill(puzzle, fixed);
cost = sudoku_cost(current);
best_cost = cost;
no_improve_count = 0;

T = 1.0;
cooling = 0.99995;
max_steps = 3e5;
restartCount = 0;

for step = 1:max_steps
    bi = randi(3)-1;
    bj = randi(3)-1;
    row_range = 3*bi+1:3*bi+3;
    col_range = 3*bj+1:3*bj+3;

    block_fixed = fixed(row_range, col_range);
    [r, c] = find(~block_fixed);
    if numel(r) < 2
        continue
    end

    idx = randperm(length(r), 2);
    i1 = row_range(r(idx(1)));
    j1 = col_range(c(idx(1)));
    i2 = row_range(r(idx(2)));
    j2 = col_range(c(idx(2)));

    trial = current;
    temp = trial(i1,j1);
    trial(i1,j1) = trial(i2,j2);
    trial(i2,j2) = temp;

    new_cost = sudoku_cost(trial);
    dE = new_cost - cost;

    if dE < 0 || rand() < exp(-dE / T)
        current = trial;
        cost = new_cost;
        if cost < best_cost
            best_cost = cost;
            no_improve_count = 0;
        else
            no_improve_count = no_improve_count + 1;
        end
    else
        no_improve_count = no_improve_count + 1;
    end

    if mod(step, 1000) == 0
        statusLabel.Text = sprintf('Step: %d | Restarts: %d | Current Cost: %d', step, restartCount, cost);
        drawnow;
    end

    if no_improve_count > 20000
        current = random_fill(puzzle, fixed);
        cost = sudoku_cost(current);
        best_cost = cost;
        no_improve_count = 0;
        T = 1.0;
        restartCount = restartCount + 1;
        statusLabel.Text = sprintf('Restart #%d at step %d', restartCount, step);
        drawnow;
    end

    T = T * cooling;

    if cost == 0
        break
    end
end

if cost == 0
    solved = current;
else
    solved = puzzle;
end
end

function cost = sudoku_cost(grid)
cost = 0;
for i = 1:9
    cost = cost + (9 - numel(unique(grid(i,:))));
    cost = cost + (9 - numel(unique(grid(:,i))));
end
for bi = 0:2
    for bj = 0:2
        block = grid(3*bi+1:3*bi+3, 3*bj+1:3*bj+3);
        cost = cost + (9 - numel(unique(block(:))));
    end
end
end

function filled = random_fill(puzzle, fixed)
filled = puzzle;
for bi = 0:2
    for bj = 0:2
        row_range = 3*bi+1:3*bi+3;
        col_range = 3*bj+1:3*bj+3;
        block = filled(row_range, col_range);
        block_fixed = fixed(row_range, col_range);
        nums = setdiff(1:9, block(block_fixed));
        empty_idx = find(~block_fixed);
        shuffled = nums(randperm(length(nums)));
        block(~block_fixed) = shuffled(1:length(empty_idx));
        filled(row_range, col_range) = block;
    end
end
end

function loadDefaultPuzzle(sudokuCells, defaultPuzzle, statusLabel)
for i = 1:9
    for j = 1:9
        val = defaultPuzzle(i, j);
        sudokuCells{i, j}.Value = val;
        if val ~= 0
            sudokuCells{i, j}.FontWeight = 'bold';
        else
            sudokuCells{i, j}.FontWeight = 'normal';
        end
        sudokuCells{i, j}.FontAngle = 'normal';
    end
end
statusLabel.Text = 'Default puzzle loaded.';
end
