classdef SOLUTION < handle
% SOLUTION - 解决方案类。
%
%   该类表示一个解决方案。SOLUTION对象存储所有属性，包括决策变量、目标值、约束违规和解决方案的附加属性。
%
% SOLUTION属性：
%   dec         <vector>    解决方案的决策变量
%   obj         <vector>    解决方案的目标值
%   con         <vector>    解决方案的约束违规
%   add         <vector>    解决方案的附加属性
%
% SOLUTION方法：
%   SOLUTION    <private>   构造函数，设置解决方案的所有属性
%   decs        <public>     获取多个解决方案的决策变量矩阵
%   objs        <public>     获取多个解决方案的目标值矩阵
%   cons        <public>     获取多个解决方案的约束违规矩阵
%   adds        <public>     获取多个解决方案的附加属性矩阵
%   best        <public>     获取多个解决方案中的可行且非支配的解决方案

%------------------------------- 版权声明 --------------------------------
% 版权所有 (c) 2024 BIMK Group。您可以将PlatEMO用于研究目的。所有使用该平台或平台中任何代码的出版物应承认使用“PlatEMO”并引用“Ye Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform for evolutionary multi-objective optimization [educational forum], IEEE Computational Intelligence Magazine, 2017, 12(4): 73-87”。
%--------------------------------------------------------------------------

    properties(SetAccess = private)
        dec;        % 解决方案的决策变量
        obj;        % 解决方案的目标值
        con;        % 解决方案的约束违规
    end
    properties
        add;        % 解决方案的附加属性
    end
    methods
        function obj = SOLUTION(PopDec, PopObj, PopCon, PopAdd)
        % SOLUTION - SOLUTION的构造函数。
        %
        %   P = SOLUTION(Dec, Obj, Con) 创建一个SOLUTION对象数组，
        %   其决策变量为Dec，目标值为Obj，约束违规为Con。
        %
        %   P = SOLUTION(Dec, Obj, Con, Add) 还设置附加属性（例如速度）。
        %
        %   Dec, Obj, Con, Add是矩阵，其中每行表示一个解决方案，
        %   每列表示变量、目标、约束或附加属性的维度。
        %
        %   示例：
        %       Population = SOLUTION(PopDec, PopObj, PopCon)
        %       Population = SOLUTION(PopDec, PopObj, PopCon, PopVel)
        
            if nargin > 0
                obj(1, size(PopDec, 1)) = SOLUTION; % 初始化SOLUTION对象数组
                for i = 1:length(obj)
                    obj(i).dec = PopDec(i, :); % 设置决策变量
                    obj(i).obj = PopObj(i, :); % 设置目标值
                    obj(i).con = PopCon(i, :); % 设置约束违规
                end
                if nargin > 3
                    for i = 1:length(obj)
                        obj(i).add = PopAdd(i, :); % 设置附加属性
                    end
                end
            end
        end
    end
    methods
        function value = decs(obj)
        % decs - 获取多个解决方案的决策变量矩阵。
        %
        %   Dec = obj.decs 返回多个解决方案obj的决策变量矩阵。
        
            value = cat(1, obj.dec); % 将所有决策变量合并为一个矩阵
        end
        
        function value = objs(obj)
        % objs - 获取多个解决方案的目标值矩阵。
        %
        %   Obj = obj.objs 返回多个解决方案obj的目标值矩阵。
        
            value = cat(1, obj.obj); % 将所有目标值合并为一个矩阵
        end
        
        function value = cons(obj)
        % cons - 获取多个解决方案的约束违规矩阵。
        %
        %   Con = obj.cons 返回多个解决方案obj的约束违规矩阵。
        
            value = cat(1, obj.con); % 将所有约束违规合并为一个矩阵
        end
        
        function value = adds(obj, Add)
        % adds - 获取或设置多个解决方案的附加属性矩阵。
        %
        %   Add = obj.adds(Add) 返回多个
        %   解决方案obj的附加属性矩阵。如果obj中的任何解决方案不包含附加属性，
        %   则将其设置为Add中指定的默认值。

            for i = 1:length(obj)
                if isempty(obj(i).add) % 检查附加属性是否为空
                    obj(i).add = Add(i, :); % 设置附加属性
                end
            end
            value = cat(1, obj.add); % 将所有附加属性合并为一个矩阵
        end
        
        function P = best(obj)
        % best - 获取多个解决方案中的最佳解决方案。
        %
        %   P = obj.best 返回多个解决方案obj中的可行且非支配的解决方案。
        %   如果解决方案只有一个目标，则返回具有最小目标值的可行解决方案。
        
            Feasible = find(all(obj.cons <= 0, 2)); % 找到所有可行的解决方案
            if isempty(Feasible)
                Best = []; % 如果没有可行的解决方案，返回空
            elseif length(obj(1).obj) > 1
                Best = NDSort(obj(Feasible).objs, 1) == 1; % 多目标情况下进行非支配排序
            else
                [~, Best] = min(obj(Feasible).objs); % 单目标情况下找到最小目标值
            end
            P = obj(Feasible(Best)); % 返回最佳解决方案
        end
    end
end
