function [vessel_graph, varargout]= fun_graph_delete_self_loop(vessel_graph, max_loop_length, verboseQ)
%  fun_graph_delete_self_loop delete all the self-loop in the vessel_graph
% Input: 
%   vessel_graph: structure generated by fun_skeleton_to_graph
% Output: 
%   vessel_graph: updated structure
%   num_self_loop: number of self-loop deleted. 
%
%
if nargin < 2
    max_loop_length = 30;
    verboseQ = false;
elseif nargin < 3
    verboseQ = false;
end
% warning('Need to debug deleting self-loop. In some case, deleting a node will create two endpoints');
self_loop = fun_graph_get_self_loops(vessel_graph);
if any(self_loop.num_voxel > max_loop_length)
    if verboseQ
        warning('Exist self-loop of length greater than %d voxels. Skip them.', max_loop_length);
        fprintf('Largest loop length: %d\n', max(self_loop.num_voxel));
        fprintf('Link label in the input graph: \n');
        disp(self_loop.link_label(self_loop.num_voxel > max_loop_length));
    end
    valid_link_Q = (self_loop.num_voxel<= max_loop_length);
    self_loop.link_label = self_loop.link_label(valid_link_Q);
    self_loop.num_voxel = self_loop.num_voxel(valid_link_Q);
end
% Delete all these links from the graph 
% fprintf('Self-loop length to be deleted:\n');
% disp(self_loop.num_voxel);
vessel_graph = fun_graph_delete_internal_links(vessel_graph, self_loop.link_label);
if nargout == 2 
    varargout{1} = numel(self_loop.link_label);
elseif nargout == 3
    varargout{1} = numel(self_loop.link_label);
    varargout{2} = self_loop;
end
end
%% Check if exist self-loop that is connected to [0,0] node
% connected_to_no_node_Q = all(vessel_graph.link.connected_node_label == 0, 2);
% ep_link_label = unique(full(vessel_graph.link.map_ind_2_label(vessel_graph.endpoint.pos_ind)));
% connected_to_no_node_link_label = find(connected_to_no_node_Q);
% wired_link_label = setdiff(connected_to_no_node_link_label, ep_link_label);