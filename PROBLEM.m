classdef PROBLEM < handle & matlab.mixin.Heterogeneous
%PROBLEM - ����ĳ��ࡣ
%
%   PROBLEM ������������ĳ��ࡣPROBLEM �Ķ���洢��������������á�

    properties
        N          = 100;      	% ��Ⱥ��С
        maxFE      = 10000;     % �������������
        FE         = 0;        	% �����ĵĺ�����������
    end
    properties(SetAccess = protected)
        M;                    	% Ŀ������
        D;                     	% ���߱�������
        maxRuntime = inf;      	% �������ʱ�䣨�룩
        encoding   = 1;        	% ÿ�����߱����ı��뷽����1.ʵ�� 2.���� 3.��ǩ 4.������ 5.���У�
        lower      = 0;     	% ÿ�����߱������½�
        upper      = 1;        	% ÿ�����߱������Ͻ�
        optimum;              	% ���������ֵ
        PF;                   	% Pareto ǰ�ص�ͼ��
        parameter  = {};       	% �������������
    end
    methods(Access = protected)
        function obj = PROBLEM(varargin)
        %PROBLEM - PROBLEM �Ĺ��캯����
        %
        %   Problem = proName('Name',Value,'Name',Value,...) ����һ��
        %   ��������������ָ����proName �� PROBLEM �����࣬��
        %   PROBLEM ����ֱ��ʵ������
        %
        %   ��� proName �� UserProblem�������ָ�����������Զ���
        %   �������ϸ��Ϣ�����򣬽����Զ������� N, M, D, maxFE, maxRuntime��
        %   ���� M, D, encoding, lower, upper ���ܻ���ָ�����Զ�������
        %
        %   ʾ����
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
        %Setting - �����Ĭ�����á�
        %
        %   �˺���Ӧ�� PROBLEM ��ÿ��������ʵ�֣�ͨ���ڹ��캯���е��á�
        end
        function Population = Initialization(obj, N)
        %Initialization - ���ɶ����ʼ�⡣
        %
        %   P = obj.Initialization() ������� obj.N ����ľ��߱��������� SOLUTION ����
        %
        %   P = obj.Initialization(N) ���� N ���⡣
        %
        %   �˺���ͨ�����㷨��ʼʱ���á�
        %
        %   ʾ����
        %       Population = Problem.Initialization()
        
            if nargin < 2
                N = obj.N;
            end
            PopDec = zeros(N, obj.D);
            Type   = arrayfun(@(i)find(obj.encoding == i), 1:5, 'UniformOutput', false);
            if ~isempty(Type{1})        % ʵ������
                PopDec(:, Type{1}) = unifrnd(repmat(obj.lower(Type{1}), N, 1), repmat(obj.upper(Type{1}), N, 1));
            end
            if ~isempty(Type{2})        % ��������
                PopDec(:, Type{2}) = round(unifrnd(repmat(obj.lower(Type{2}), N, 1), repmat(obj.upper(Type{2}), N, 1)));
            end
            if ~isempty(Type{3})        % ��ǩ����
                PopDec(:, Type{3}) = round(unifrnd(repmat(obj.lower(Type{3}), N, 1), repmat(obj.upper(Type{3}), N, 1)));
            end
            if ~isempty(Type{4})        % �����Ʊ���
                PopDec(:, Type{4}) = logical(randi([0, 1], N,length(Type{4})));
            end
            if ~isempty(Type{5})        % ���б���
                [~, PopDec(:, Type{5})] = sort(rand(N, length(Type{5})), 2);
            end
            Population = obj.Evaluation(PopDec);
        end
        function Population = Evaluation(obj, varargin)
        %Evaluation - ��������⡣
        %
        %   P = obj.Evaluation(Dec) ���ݾ��߱��� Dec ���� SOLUTION ����
        %   ���Ŀ��ֵ��Լ��Υ����Զ����㣬����Ӧ���� obj.FE��
        %
        %   P = obj.Evaluation(Dec, Add) �����ý�ĸ������ԣ����磬�ٶȣ���
        %
        %   �˺���ͨ���������½����á�
        %
        %   ʾ����
        %       Population = Problem.Evaluation(PopDec)
        %       Population = Problem.Evaluation(PopDec, PopVel)
        
            PopDec     = obj.CalDec(varargin{1});
            PopObj     = obj.CalObj(PopDec);
            PopCon     = obj.CalCon(PopDec);
            Population = SOLUTION(PopDec, PopObj, PopCon, varargin{2:end});
            obj.FE     = obj.FE + length(Population);
        end
        function PopDec = CalDec(obj, PopDec)
        %CalDec - �޸������Ч�⡣
        %
        %   Dec = obj.CalDec(Dec) �޸� Dec �е���Ч�������ʣ����߱�����
        %
        %   ��Ч���ʾ�䳬�����߿ռ䣬�������ʽ��ʾ�䲻��������Լ����
        %
        %   �˺���ͨ���� PROBLEM.Evaluation ���á�
        %
        %   ʾ����
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
        %CalObj - ���������Ŀ��ֵ��
        %
        %   Obj = obj.CalObj(Dec) ���� Dec ��Ŀ��ֵ��
        %
        %   �˺���ͨ���� PROBLEM.Evaluation ���á�
        %
        %   ʾ����
        %       PopObj = Problem.CalObj(PopDec)

            PopObj = zeros(size(PopDec, 1), 1);
        end
        function PopCon = CalCon(obj, PopDec)
        %CalCon - ���������Լ��Υ�档
        %
        %   Con = obj.CalCon(Dec) ���� Dec ��Լ��Υ�档
        %
        %   �˺���ͨ���� PROBLEM.Evaluation ���á�
        %
        %   ʾ����
        %       PopCon = Problem.CalCon(PopDec)
        
            PopCon = zeros(size(PopDec, 1), 1);
        end
        function [ObjGrad, ConGrad] = CalGrad(obj, Dec)
        %CalGrad - ������Ŀ���Լ�����ݶȡ�
        %
        %   [OGrad, CGrad] = obj.CalGrad(Dec) ���� Dec ��Ŀ�� OGrad ��Լ�� CGrad ���ݶȣ����ſɱȾ���
        %
        %   �˺���ͨ���ɻ����ݶȵ��㷨���á�
        %
        %   ʾ����
        %       [ObjGrad, ConGrad] = Problem.CalGrad(Dec)
        
            Dec(Dec == 0) = 1e-12;  % ���������
            P1 = obj.Evaluation(Dec);
            P2 = obj.Evaluation(repmat(Dec, obj.D, 1) .* (1 + eye(obj.D) * 1e-6));
            ObjGrad = (P2.objs - repmat(P1.objs, obj.D, 1))' ./ Dec ./ 1e-6;
            ConGrad = (P2.cons - repmat(P1.cons, obj.D, 1))' ./ Dec ./ 1e-6;
            obj.FE  = obj.FE - obj.D;  % ���������ĵĺ�����������
        end
        function R = GetOptimum(obj, N)
        %GetOptimum - ������������Ž⡣
        %
        %   R = obj.GetOptimum(N) ���� N ����������Ž⣬���ڶ������㡣
        %
        %   ���ڵ�Ŀ���Ż����⣬���Ž�������������СĿ��ֵ��
        %
        %   ���ڶ�Ŀ���Ż����⣬���Ž������ Pareto ǰ���ϵ�һ���㣻��� Pareto ǰ��δ֪�����Ž���������ڳ��������Ĳο��㡣
        %
        %   �˺���ͨ���ڹ��캯���е��á�
        %
        %   ʾ����
        %       R = Problem.GetOptimum(10000)
        
            if obj.M > 1
                R = ones(1, obj.M);  % ��Ŀ����������Ž�
            else
                R = 0;  % ��Ŀ����������Ž�
            end
        end
        function R = GetPF(obj)
        %GetPF - ���� Pareto ǰ�ص�ͼ��
        %
        %   R = obj.GetPF() ��������Ŀ����ӻ��� Pareto ǰ�ص�ͼ��
        %
        %   ���ڵ�Ŀ���Ż����⣬�˺������á�
        %
        %   ����˫Ŀ���Ż����⣬ͼ��ӦΪһά���ߡ�
        %
        %   ������Ŀ���Ż����⣬ͼ��ӦΪ��ά���档
        %
        %   ������Լ����˫Ŀ���Ż����⣬ͼ������ǿ�������
        %
        %   �˺���ͨ���ڹ��캯���е��á�
        %
        %   ʾ����
        %       R = Problem.GetPF()
        
            R = [];  % Ĭ�Ϸ��ؿ�
        end
        function score = CalMetric(obj, metName, Population)
        %CalMetric - ������Ⱥ�Ķ���ֵ��
        %
        %   value = obj.CalMetric(Met, P) ������Ⱥ P �Ķ���ֵ������ Met ��һ���ַ�������ʾ�������������ơ�
        %
        %   ʾ����
        %       value = Problem.CalMetric('HV', Population);
        
            score = feval(metName, Population, obj.optimum);  % �������ֵ
        end
        function DrawDec(obj, Population)
        %DrawDec - �ھ��߿ռ�����ʾ��Ⱥ��
        %
        %   obj.DrawDec(P) ��ʾ��Ⱥ P �ľ��߱�����
        %
        %   �˺���ͨ���� GUI ���á�
        %
        %   ʾ����
        %       Problem.DrawDec(Population)
        
            if all(obj.encoding == 4)  % ������б������Ƕ�����
                Draw(logical(Population.decs));  % ���ƶ����ƾ��߱���
            else
                Draw(Population.decs, {'\it x\rm_1', '\it x\rm_2', '\it x\rm_3'});  % �����������͵ľ��߱���
            end
        end
        function DrawObj(obj, Population)
        %DrawObj - ��Ŀ��ռ�����ʾ��Ⱥ��
        %
        %   obj.DrawObj(P) ��ʾ��Ⱥ P ��Ŀ��ֵ��
        %
        %   �˺���ͨ���� GUI ���á�
        %
        %   ʾ����
        %       Problem.DrawObj(Population)

            ax = Draw(Population.objs, {'\it f\rm_1', '\it f\rm_2', '\it f\rm_3'});  % ����Ŀ��ֵ
            if ~isempty(obj.PF)
                if ~iscell(obj.PF)
                    if obj.M == 2
                        plot(ax, obj.PF(:, 1), obj.PF(:, 2), '-k', 'LineWidth', 1);  % ���ƶ�Ŀ��� Pareto ǰ��
                    elseif obj.M == 3
                        plot3(ax, obj.PF(:, 1), obj.PF(:, 2), obj.PF(:, 3), '-k', 'LineWidth', 1);  % ������Ŀ��� Pareto ǰ��
                    end
                else
                    if obj.M == 2
                        surf(ax, obj.PF{1}, obj.PF{2}, obj.PF{3}, 'EdgeColor', 'none', 'FaceColor', [.85 .85 .85]);  % ����˫Ŀ��ı���
                    elseif obj.M == 3
                        surf(ax, obj.PF{1}, obj.PF{2}, obj.PF{3}, 'EdgeColor', [.8 .8 .8],'FaceColor', 'none');  % ������Ŀ��ı���
                    end
                    set(ax, 'Children', ax.Children(flip(1:end)));  % ��ת��ͼ˳��
                end
            elseif size(obj.optimum, 1) > 1 && obj.M < 4
                if obj.M == 2
                    plot(ax, obj.optimum(:, 1), obj.optimum(:, 2), '.k');  % �������Ž��
                elseif obj.M == 3
                    plot3(ax, obj.optimum(:, 1), obj.optimum(:, 2), obj.optimum(:, 3), '.k');  % ������ά���Ž��
                end
            end
        end
    end
    methods(Access = protected, Sealed)
        function varargout = ParameterSet(obj, varargin)
        %ParameterSet - ��ȡ����Ĳ�����
        %
        %   [p1, p2, ...] = obj.ParameterSet(v1, v2, ...) ���ò��� p1, p2, ... ��ֵ��
        %   ��� obj.parameter ��ָ������ÿ����������Ϊ obj.parameter �и�����ֵ��
        %   ��������Ϊ v1, v2, ... �и�����ֵ��
        %
        %   �˺���ͨ���� PROBLEM.Setting ���á�
        %
        %   ʾ����
        %       [p1, p2, p3] = obj.ParameterSet(1, 2, 3)

            varargout = varargin;  % Ĭ�Ϸ����������
            specified = ~cellfun(@isempty, obj.parameter);  % �������Ƿ�ָ��
            varargout(specified) = obj.parameter(specified);  % ��ָ���Ĳ����滻�������
        end
    end
end



