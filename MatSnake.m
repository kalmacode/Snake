%% MatSnake by KalMa    #MatFunZone (2018)
%  contact: maciej.kalarus@gmail.com
%  ------------------------------------------------------------------------
%  How to play
%  - press space to start
%  - use arrows to control snake

function MatSnake
    global Game
    
    Game.Name                   = 'MatSnake';
    Game.Version                = 1.1;
    Game.Speed                  = 4;            % [steps per second]
    Game.Level                  = 1;

    %% Board
    Game.Board.Size             = [15 20];      % [X Y]
    Game.Board.Color            = [0.8 0.9 0.8];
    Game.Board.BackgroundColor  = [0.0 0.6 0.0];
    Game.Board.FieldSize        = 20;           % size of the single field [px]

    %% Snake properties
    Game.Snake.Head  = struct('Marker','.', 'MarkerSize',50, 'Color',[0 0 0.7]);
    Game.Snake.Body  = struct('Marker','.', 'MarkerSize',40, 'Color',[0 0 0.9]);
    Game.Snake.Tail  = struct('Marker','.', 'MarkerSize',30, 'Color',[0 0 0.5]);
    %% Snake's food
    Game.Snake.Food  = struct('Marker','h', 'MarkerSize',15, 'Color',[0 0.5 0], 'MarkerFaceColor',[0.3 0.3 0.3]);

    %% Timer
    Game.hTimer = timer('Period',1/Game.Speed,...
                        'ExecutionMode','fixedRate',...
                        'StartFcn',@(~,~)GameRestart(),...
                        'TimerFcn',@(~,~)GamePlay());
    
    %% application window
    ScreenSize = get(0,'ScreenSize');
    S = Game.Board.Size * Game.Board.FieldSize;
    figure( 'Units','pixels',...
            'Position',[(ScreenSize(3:4) - S)*0.5, S] + [0 0 0 46],...
            'MenuBar','none',...
            'NumberTitle','off',...
            'Resize','off',...
            'Color',Game.Board.BackgroundColor,...
            'Name',[Game.Name, ' by KalMa'],...
            'KeyPressFcn',@(~,evnt)KeyPress(evnt.Key),...
            'CloseRequestFcn',@(~,~)CloseApp());
    
    axes( 'Units','pixels',...
          'Position',[1 20 S-1],...
          'NextPlot','add',...
          'box','on',...
          'Color',Game.Board.Color,...
          'xlim',[0 Game.Board.Size(1)] + 0.5,...
          'ylim',[0 Game.Board.Size(2)] + 0.5,...
          'XTick',[],...
          'YTick',[]);
    
    title(sprintf('%s v%0.1f', Game.Name, Game.Version));

    Game.hInfo  = text('Position',Game.Board.Size/2 + [0.5 0], 'String','press space to start',...
                       'Horizontalalignment','center', 'Color','red', 'FontSize',14, 'FontWeight','bold');
    Game.hScore = text(1,0,'Score: 0', 'FontWeight','bold');
    Game.hLevel = text(5,0,'Level: 1', 'FontWeight','bold');
    Game.hFood  = line(0,0,Game.Snake.Food);
    Game.hSnake(1,prod(Game.Board.Size)) = matlab.graphics.chart.primitive.Line;
end

function GameRestart()
    global Game
    Game.hInfo.Visible      = 'off';
    Game.Score              = 0;
    Game.Level              = 1;
    Game.StopTail           = 0;
    Game.hScore.String      = 'Score: 0';
    Game.hLevel.String      = 'Level: 1';
    Game.Snake.HeadPosition = [round(Game.Board.Size(1)/2), 3];
    Game.Snake.Direction    = 'u'; % go up
    
    Game.SnakeHeadId        = 1;
    Game.SnakeTailId        = 3;
    
    delete(Game.hSnake);
    SH = Game.Snake.HeadPosition;
    Game.hSnake(1) = line(SH(1), SH(2),   Game.Snake.Head);
    Game.hSnake(2) = line(SH(1), SH(2)-1, Game.Snake.Body);
    Game.hSnake(3) = line(SH(1), SH(2)-2, Game.Snake.Tail);
    PutFood();
end

function GamePlay()
    global Game
    SD = Game.Snake.Direction;
    SH = Game.Snake.HeadPosition;
    SH = SH + [(SD=='r') - (SD=='l'), (SD=='u') - (SD=='d')]; % move snake in a current direction
    if any(SH<1) || any(SH>Game.Board.Size) || ~isempty(findobj(Game.hSnake,'XData',SH(1),'-and','YData',SH(2))) % if isGameOver
        stop(Game.hTimer);
        uistack(Game.hInfo,'top');
        set(Game.hInfo, 'String','Game Over', 'Visible','on');
    else
        % move head
        set(Game.hSnake(Game.SnakeHeadId),Game.Snake.Body);
        Game.SnakeHeadId = mod(Game.SnakeHeadId - 2,length(Game.hSnake)) + 1; 
        Game.hSnake(Game.SnakeHeadId) = line(SH(1),SH(2),Game.Snake.Head);

        if Game.hFood.XData == SH(1) && Game.hFood.YData == SH(2) % check for food
            Game.Score = Game.Score + 1;
            Game.hScore.String = sprintf('Score: %d',Game.Score);
            PutFood();
            if ~mod(Game.Score,10)
                Game.Level = Game.Level + 1;
                Game.hLevel.String = sprintf('Level: %d',Game.Level);
            end
            Game.StopTail = Game.StopTail + Game.Level;
        end
        
        if Game.StopTail
            Game.StopTail = Game.StopTail - 1;
        else % move tail
            delete(Game.hSnake(Game.SnakeTailId));
            Game.SnakeTailId = mod(Game.SnakeTailId - 2,length(Game.hSnake)) + 1; 
            set(Game.hSnake(Game.SnakeTailId),Game.Snake.Tail);
        end

        % diversify snake's body color
        if Game.SnakeHeadId < Game.SnakeTailId
            c = Game.SnakeHeadId:Game.SnakeTailId;
        else
            c = [Game.SnakeHeadId:length(Game.hSnake), 1:Game.SnakeTailId];
        end
        set(Game.hSnake(c),{'Color'},mat2cell((1 - ~mod(0:length(c)-1,4)*0.8)' * Game.Snake.Body.Color, ones(size(c)), 3));
        
        Game.Snake.HeadPosition = SH;
    end
end

function KeyPress(key)
    global Game
    switch key
        case 'space'
            if strcmp(Game.hTimer.Running,'on')
                stop(Game.hTimer);
            end
            start(Game.hTimer);
        case {'uparrow','downarrow','rightarrow','leftarrow'}
            Game.Snake.Direction = key(1);
    end
end

function PutFood()
    global Game
    isOccupied = true;
    while (isOccupied)
        FP = floor(rand(1,2) .* Game.Board.Size)+1;
        isOccupied = ~isempty(findobj(Game.hSnake,'XData',FP(1),'-and','YData',FP(2)));
    end
    set(Game.hFood,'XData',FP(1), 'YData',FP(2));
end

function CloseApp()
    global Game
    stop(Game.hTimer);
    delete(gcf);
end
