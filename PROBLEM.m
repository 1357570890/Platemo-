classdef PROBLEM < handle & matlab.mixin.Heterogeneous
%PROBLEM - 问题的超类。
%
%   PROBLEM 类是所有问题的超类。PROBLEM 的对象存储了问题的所有设置。

    properties
        N          = 100;      	% 种群大小
        maxFE      = 10000;     % 最大函数评估次数
        FE         = 0;        	% 已消耗的函数评估次数
    end
    properties(SetAccess = protected)
        M;                    	% 目标数量
        D;                     	% 决策变量数量
        maxRuntime = inf;      	% 最大运行时间（秒）
        encoding   = 1;        	% 每个决策变量的编码方案（1.实数 2.整数 3.标签 4.二进制 5.排列）
        lower      = 0;     	% 每个决策变量的下界
        upper      = 1;        	% 每个决策变量的上界
        optimum;              	% 问题的最优值
        PF;                   	% Pareto 前沿的图像
        parameter  = {};       	% 问题的其他参数
    end
    methods(Access = protected)
        function obj = PROBLEM(varargin)
        %PROBLEM - PROBLEM 的构造函数。
        %
        %   Problem = proName('Name',Value,'Name',Value,...) 生成一个
        %   对象，属性由输入指定。proName 是 PROBLEM 的子类，而
        %   PROBLEM 不能直接实例化。
        %
        %   如果 proName 是 UserProblem，则可以指定所有属性以定义
        %   问题的详细信息。否则，仅可以定义属性 N, M, D, maxFE, maxRuntime。
        %   属性 M, D, encoding, lower, upper 可能会在指定后自动修正。
        %
        %   示例：
        %       Problem = UserProblem('objFcn',@(x)sum(x,2))
        %       Problem = DTLZ2('M',5,'D',10)

            isStr = find(cellfun(@ischar,varargin(1:end-1)) & ~cellfun(@isempty,varargin(2:end)));
            for i = isStr(ismember(varargin(isStr), {'N', 'M', 'D', 'maxFE', 'maxRuntime', 'parameter'}))
                obj.(varargin{i}) = varargin{i+1};
            end
            obj.Setting();
            obj.optimum  = obj.GetOptimum(10000);
            obj.PF       = obj.GetPF();
        end
    end
    methods
        function Setting(obj)
        %Setting - 问题的默认设置。
        %
        %   此函数应在 PROBLEM 的每个子类中实现，通常在构造函数中调用。
        end
        function Population = Initialization(obj, N)
        %Initialization - 生成多个初始解。
        %
        %   P = obj.Initialization() 随机生成 obj.N 个解的决策变量并返回 SOLUTION 对象。
        %
        %   P = obj.Initialization(N) 生成 N 个解。
        %
        %   此函数通常在算法开始时调用。
        %
        %   示例：
        %       Population = Problem.Initialization()
        
            if nargin < 2
                N = obj.N;
            end
            PopDec = zeros(N, obj.D);
            Type   = arrayfun(@(i)find(obj.encoding == i), 1:5, 'UniformOutput', false);
            if ~isempty(Type{1})        % 实数变量
                PopDec(:, Type{1}) = unifrnd(repmat(obj.lower(Type{1}), N, 1), repmat(obj.upper(Type{1}), N, 1));
            end
            if ~isempty(Type{2})        % 整数变量
                PopDec(:, Type{2}) = round(unifrnd(repmat(obj.lower(Type{2}), N, 1), repmat(obj.upper(Type{2}), N, 1)));
            end
            if ~isempty(Type{3})        % 标签变量
                PopDec(:, Type{3}) = round(unifrnd(repmat(obj.lower(Type{3}), N, 1), repmat(obj.upper(Type{3}), N, 1)));
            end
            if ~isempty(Type{4})        % 二进制变量
                PopDec(:, Type{4}) = logical(randi([0, 1], N,length(Type{4})));
            end
            if ~isempty(Type{5})        % 排列变量
                [~, PopDec(:, Type{5})] = sort(rand(N, length(Type{5})), 2);
            end
            Population = obj.Evaluation(PopDec);
        end
        function Population = Evaluation(obj, varargin)
        %Evaluation - 评估多个解。
        %
        %   P = obj.Evaluation(Dec) 根据决策变量 Dec 返回 SOLUTION 对象。
        %   解的目标值和约束违规会自动计算，并相应增加 obj.FE。
        %
        %   P = obj.Evaluation(Dec, Add) 还设置解的附加属性（例如，速度）。
        %
        %   此函数通常在生成新解后调用。
        %
        %   示例：
        %       Population = Problem.Evaluation(PopDec)
        %       Population = Problem.Evaluation(PopDec, PopVel)
        
            PopDec     = obj.CalDec(varargin{1});
            PopObj     = obj.CalObj(PopDec);
            PopCon     = obj.CalCon(PopDec);
            Population = SOLUTION(PopDec, PopObj, PopCon, varargin{2:end});
            obj.FE     = obj.FE + length(Population);
        end
        function PopDec = CalDec(obj, PopDec)
        %CalDec - 修复多个无效解。
        %
        %   Dec = obj.CalDec(Dec) 修复 Dec 中的无效（不合适）决策变量。
        %
        %   无效解表示其超出决策空间，而不合适解表示其不满足所有约束。
        %
        %   此函数通常由 PROBLEM.Evaluation 调用。
        %
        %   示例：
        %       PopDec = Problem.CalDec(PopDec)

            Type  = arrayfun(@(i)find(obj.encoding == i), 1:5, 'UniformOutput', false);
            index = [Type{1:3}];
            if ~isempty(index)
                PopDec(:, index) = max(min(PopDec(:, index), repmat(obj.upper(index), size(PopDec, 1), 1)), repmat(obj.lower(index), size(PopDec, 1), 1));
            end
            index = [Type{2:5}];
            if ~isempty(index)
                PopDec(:, index) = round(PopDec(:, index));
            end
        end
        function PopObj = CalObj(obj, PopDec)
        %CalObj - 计算多个解的目标值。
        %
        %   Obj = obj.CalObj(Dec) 返回 Dec 的目标值。
        %
        %   此函数通常由 PROBLEM.Evaluation 调用。
        %
        %   示例：
        %       PopObj = Problem.CalObj(PopDec)

            PopObj = zeros(size(PopDec, 1), 1);
        end
        function PopCon = CalCon(obj, PopDec)
        %CalCon - 计算多个解的约束违规。
        %
        %   Con = obj.CalCon(Dec) 返回 Dec 的约束违规。
        %
        %   此函数通常由 PROBLEM.Evaluation 调用。
        %
        %   示例：
        %       PopCon = Problem.CalCon(PopDec)
        
            PopCon = zeros(size(PopDec, 1), 1);
        end
        function [ObjGrad, ConGrad] = CalGrad(obj, Dec)
        %CalGrad - 计算解的目标和约束的梯度。
        %
        %   [OGrad, CGrad] = obj.CalGrad(Dec) 返回 Dec 的目标 OGrad 和约束 CGrad 的梯度，即雅可比矩阵。
        %
        %   此函数通常由基于梯度的算法调用。
        %
        %   示例：
        %       [ObjGrad, ConGrad] = Problem.CalGrad(Dec)
        
            Dec(Dec == 0) = 1e-12;  % 避免除以零
            P1 = obj.Evaluation(Dec);
            P2 = obj.Evaluation(repmat(Dec, obj.D, 1) .* (1 + eye(obj.D) * 1e-6));
            ObjGrad = (P2.objs - repmat(P1.objs, obj.D, 1))' ./ Dec ./ 1e-6;
            ConGrad = (P2.cons - repmat(P1.cons, obj.D, 1))' ./ Dec ./ 1e-6;
            obj.FE  = obj.FE - obj.D;  % 更新已消耗的函数评估次数
        end
        function R = GetOptimum(obj, N)
        %GetOptimum - 生成问题的最优解。
        %
        %   R = obj.GetOptimum(N) 返回 N 个问题的最优解，用于度量计算。
        %
        %   对于单目标优化问题，最优解可以是问题的最小目标值。
        %
        %   对于多目标优化问题，最优解可以是 Pareto 前沿上的一个点；如果 Pareto 前沿未知，最优解可以是用于超体积计算的参考点。
        %
        %   此函数通常在构造函数中调用。
        %
        %   示例：
        %       R = Problem.GetOptimum(10000)
        
            if obj.M > 1
                R = ones(1, obj.M);  % 多目标问题的最优解
            else
                R = 0;  % 单目标问题的最优解
            end
        end
        function R = GetPF(obj)
        %GetPF - 生成 Pareto 前沿的图像。
        %
        %   R = obj.GetPF() 返回用于目标可视化的 Pareto 前沿的图像。
        %
        %   对于单目标优化问题，此函数无用。
        %
        %   对于双目标优化问题，图像应为一维曲线。
        %
        %   对于三目标优化问题，图像应为二维表面。
        %
        %   对于受约束的双目标优化问题，图像可以是可行区域。
        %
        %   此函数通常在构造函数中调用。
        %
        %   示例：
        %       R = Problem.GetPF()
        
            R = [];  % 默认返回空
        end
        function score = CalMetric(obj, metName, Population)
        %CalMetric - 计算种群的度量值。
        %
        %   value = obj.CalMetric(Met, P) 返回种群 P 的度量值，其中 Met 是一个字符串，表示度量函数的名称。
        %
        %   示例：
        %       value = Problem.CalMetric('HV', Population);
        
            score = feval(metName, Population, obj.optimum);  % 计算度量值
        end
        function DrawDec(obj, Population)
        %DrawDec - 在决策空间中显示种群。
        %
        %   obj.DrawDec(P) 显示种群 P 的决策变量。
        %
        %   此函数通常由 GUI 调用。
        %
        %   示例：
        %       Problem.DrawDec(Population)
        
            if all(obj.encoding == 4)  % 如果所有变量都是二进制
                Draw(logical(Population.decs));  % 绘制二进制决策变量
            else
                Draw(Population.decs, {'\it x\rm_1', '\it x\rm_2', '\it x\rm_3'});  % 绘制其他类型的决策变量
            end
        end
        function DrawObj(obj, Population)
        %DrawObj - 在目标空间中显示种群。
        %
        %   obj.DrawObj(P) 显示种群 P 的目标值。
        %
        %   此函数通常由 GUI 调用。
        %
        %   示例：
        %       Problem.DrawObj(Population)

            ax = Draw(Population.objs, {'\it f\rm_1', '\it f\rm_2', '\it f\rm_3'});  % 绘制目标值
            if ~isempty(obj.PF)
                if ~iscell(obj.PF)
                    if obj.M == 2
                        plot(ax, obj.PF(:, 1), obj.PF(:, 2), '-k', 'LineWidth', 1);  % 绘制二目标的 Pareto 前沿
                    elseif obj.M == 3
                        plot3(ax, obj.PF(:, 1), obj.PF(:, 2), obj.PF(:, 3), '-k', 'LineWidth', 1);  % 绘制三目标的 Pareto 前沿
                    end
                else
                    if obj.M == 2
                        surf(ax, obj.PF{1}, obj.PF{2}, obj.PF{3}, 'EdgeColor', 'none', 'FaceColor', [.85 .85 .85]);  % 绘制双目标的表面
                    elseif obj.M == 3
                        surf(ax, obj.PF{1}, obj.PF{2}, obj.PF{3}, 'EdgeColor', [.8 .8 .8],'FaceColor', 'none');  % 绘制三目标的表面
                    end
                    set(ax, 'Children', ax.Children(flip(1:end)));  % 反转绘图顺序
                end
            elseif size(obj.optimum, 1) > 1 && obj.M < 4
                if obj.M == 2
                    plot(ax, obj.optimum(:, 1), obj.optimum(:, 2), '.k');  % 绘制最优解点
                elseif obj.M == 3
                    plot3(ax, obj.optimum(:, 1), obj.optimum(:, 2), obj.optimum(:, 3), '.k');  % 绘制三维最优解点
                end
            end
        end
    end
    methods(Access = protected, Sealed)
        function varargout = ParameterSet(obj, varargin)
        %ParameterSet - 获取问题的参数。
        %
        %   [p1, p2, ...] = obj.ParameterSet(v1, v2, ...) 设置参数 p1, p2, ... 的值，
        %   如果 obj.parameter 被指定，则每个参数设置为 obj.parameter 中给定的值，
        %   否则设置为 v1, v2, ... 中给定的值。
        %
        %   此函数通常由 PROBLEM.Setting 调用。
        %
        %   示例：
        %       [p1, p2, p3] = obj.ParameterSet(1, 2, 3)

            varargout = varargin;  % 默认返回输入参数
            specified = ~cellfun(@isempty, obj.parameter);  % 检查参数是否被指定
            varargout(specified) = obj.parameter(specified);  % 用指定的参数替换输入参数
        end
    end
end



