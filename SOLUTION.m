classdef SOLUTION < handle
% SOLUTION - ��������ࡣ
%
%   �����ʾһ�����������SOLUTION����洢�������ԣ��������߱�����Ŀ��ֵ��Լ��Υ��ͽ�������ĸ������ԡ�
%
% SOLUTION���ԣ�
%   dec         <vector>    ��������ľ��߱���
%   obj         <vector>    ���������Ŀ��ֵ
%   con         <vector>    ���������Լ��Υ��
%   add         <vector>    ��������ĸ�������
%
% SOLUTION������
%   SOLUTION    <private>   ���캯�������ý����������������
%   decs        <public>     ��ȡ�����������ľ��߱�������
%   objs        <public>     ��ȡ������������Ŀ��ֵ����
%   cons        <public>     ��ȡ������������Լ��Υ�����
%   adds        <public>     ��ȡ�����������ĸ������Ծ���
%   best        <public>     ��ȡ�����������еĿ����ҷ�֧��Ľ������

%------------------------------- ��Ȩ���� --------------------------------
% ��Ȩ���� (c) 2024 BIMK Group�������Խ�PlatEMO�����о�Ŀ�ġ�����ʹ�ø�ƽ̨��ƽ̨���κδ���ĳ�����Ӧ����ʹ�á�PlatEMO�������á�Ye Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform for evolutionary multi-objective optimization [educational forum], IEEE Computational Intelligence Magazine, 2017, 12(4): 73-87����
%--------------------------------------------------------------------------

    properties(SetAccess = private)
        dec;        % ��������ľ��߱���
        obj;        % ���������Ŀ��ֵ
        con;        % ���������Լ��Υ��
    end
    properties
        add;        % ��������ĸ�������
    end
    methods
        function obj = SOLUTION(PopDec, PopObj, PopCon, PopAdd)
        % SOLUTION - SOLUTION�Ĺ��캯����
        %
        %   P = SOLUTION(Dec, Obj, Con) ����һ��SOLUTION�������飬
        %   ����߱���ΪDec��Ŀ��ֵΪObj��Լ��Υ��ΪCon��
        %
        %   P = SOLUTION(Dec, Obj, Con, Add) �����ø������ԣ������ٶȣ���
        %
        %   Dec, Obj, Con, Add�Ǿ�������ÿ�б�ʾһ�����������
        %   ÿ�б�ʾ������Ŀ�ꡢԼ���򸽼����Ե�ά�ȡ�
        %
        %   ʾ����
        %       Population = SOLUTION(PopDec, PopObj, PopCon)
        %       Population = SOLUTION(PopDec, PopObj, PopCon, PopVel)
        
            if nargin > 0
                obj(1, size(PopDec, 1)) = SOLUTION; % ��ʼ��SOLUTION��������
                for i = 1:length(obj)
                    obj(i).dec = PopDec(i, :); % ���þ��߱���
                    obj(i).obj = PopObj(i, :); % ����Ŀ��ֵ
                    obj(i).con = PopCon(i, :); % ����Լ��Υ��
                end
                if nargin > 3
                    for i = 1:length(obj)
                        obj(i).add = PopAdd(i, :); % ���ø�������
                    end
                end
            end
        end
    end
    methods
        function value = decs(obj)
        % decs - ��ȡ�����������ľ��߱�������
        %
        %   Dec = obj.decs ���ض���������obj�ľ��߱�������
        
            value = cat(1, obj.dec); % �����о��߱����ϲ�Ϊһ������
        end
        
        function value = objs(obj)
        % objs - ��ȡ������������Ŀ��ֵ����
        %
        %   Obj = obj.objs ���ض���������obj��Ŀ��ֵ����
        
            value = cat(1, obj.obj); % ������Ŀ��ֵ�ϲ�Ϊһ������
        end
        
        function value = cons(obj)
        % cons - ��ȡ������������Լ��Υ�����
        %
        %   Con = obj.cons ���ض���������obj��Լ��Υ�����
        
            value = cat(1, obj.con); % ������Լ��Υ��ϲ�Ϊһ������
        end
        
        function value = adds(obj, Add)
        % adds - ��ȡ�����ö����������ĸ������Ծ���
        %
        %   Add = obj.adds(Add) ���ض��
        %   �������obj�ĸ������Ծ������obj�е��κν�������������������ԣ�
        %   ��������ΪAdd��ָ����Ĭ��ֵ��

            for i = 1:length(obj)
                if isempty(obj(i).add) % ��鸽�������Ƿ�Ϊ��
                    obj(i).add = Add(i, :); % ���ø�������
                end
            end
            value = cat(1, obj.add); % �����и������Ժϲ�Ϊһ������
        end
        
        function P = best(obj)
        % best - ��ȡ�����������е���ѽ��������
        %
        %   P = obj.best ���ض���������obj�еĿ����ҷ�֧��Ľ��������
        %   ����������ֻ��һ��Ŀ�꣬�򷵻ؾ�����СĿ��ֵ�Ŀ��н��������
        
            Feasible = find(all(obj.cons <= 0, 2)); % �ҵ����п��еĽ������
            if isempty(Feasible)
                Best = []; % ���û�п��еĽ�����������ؿ�
            elseif length(obj(1).obj) > 1
                Best = NDSort(obj(Feasible).objs, 1) == 1; % ��Ŀ������½��з�֧������
            else
                [~, Best] = min(obj(Feasible).objs); % ��Ŀ��������ҵ���СĿ��ֵ
            end
            P = obj(Feasible(Best)); % ������ѽ������
        end
    end
end
