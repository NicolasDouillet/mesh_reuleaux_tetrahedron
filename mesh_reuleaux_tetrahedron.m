function [V, T] = mesh_reuleaux_tetrahedron(sample_step, option_display)
%% mesh_reuleaux_tetrahedron : function to compute and display the mesh of a Reuleaux tetrahedron. 
%
% Authors : nicolas.douillet (at) free.fr, 2017-2024.
%
%
% Syntax
%
% mesh_reuleaux_tetrahedron;
% mesh_reuleaux_tetrahedron(sample_step);
% mesh_reuleaux_tetrahedron(sample_step);
% mesh_reuleaux_tetrahedron(sample_step, option_display);
% [V, T] = mesh_reuleaux_tetrahedron(sample_step, option_display);
%
%
% Description
%
% mesh_reuleaux_tetrahedron computes and displays the mesh Reuleaux
% tetrahedron included in the unit sphere, and which each
% edge is sampled in 32.
%
% mesh_reuleaux_tetrahedron(sample_step) uses sample_step steps.
%
% mesh_reuleaux_tetrahedron(sample_step, option_display)
% displays the result when option_display is logical *true/1, and doesn't when it is
% logical false/0.
%
% [V, T] = mesh_reuleaux_tetrahedron(sample_step, option_display) stores the resulting
% vertices coordinates in the array V, and the corresponding triplet indices list in the array T.
% 
%
% See also MESH, TRIMESH.
%
%
% Input arguments
%
% - sample_step : positive integer scalar double, , power of 2. Optional.
%
% - option_display : logical *true (1) / false (0). Optional.
%
%
% Output arguments
%
%     [ |  |  |]
% - V [Vx Vy Vz] : real matrix double, the point set. Size = [nb_vertices,3].
%     [ |  |  |]
%
%     [ |  |  |]
% - T [T1 T2 T3] : positive integer matrix double, the triangulation. Size = [nb_triangles,3].
%     [ |  |  |]
%
%
% Example #1
% Computes and displays the standard mesh Reuleaux tetrahedron,
% included in the unit sphere, and which each edge is divided into 32 samples.
%
% mesh_reuleaux_tetrahedron;
%
% Example #2
% Computes, displays, and saves a mesh Reuleaux tetrahedron,
% which each edge is divided into 8 samples. Radius size is then increased to 9.
% 
% [V,T] = mesh_reuleaux_tetrahedron(8,'inflated',true);
% V = 9*V;


%% Input parsing
assert(nargin < 3,'Too many input arguments.');

if nargin > 0
    
    assert(isnumeric(sample_step) && sample_step == floor(sample_step) && sample_step > 0,'sample_step parameter must be a positive integer.');  
    
else        
    
    sample_step = 32;
    
end

if nargin > 1    
    
    assert(islogical(option_display) || isnumeric(option_display),'option_display parameter type must be either logical or numeric.');            
    
else   
    
    option_display = true;     
    
end        


%% Body
%  Summits of original tetrahedron, living in the sphere S(O,1)
V1 = [0 0 1];
V2 = [2*sqrt(2)/3 0 -1/3];
V3 = [-sqrt(2)/3 sqrt(6)/3 -1/3];
V4 = [-sqrt(2)/3 -sqrt(6)/3 -1/3];

edge_length = norm(V1-V2); %  = 2*sqrt(6)/3

[V123, T] = sample_and_curve_triangle(V1',V2',V3',sample_step,0.85);
V123 = inflate_triangle_sample_from_opposite_vertex(V123,V4,edge_length);

% Tetrahedron faces rotations
Rmy = @(theta) [cos(theta) 0 -sin(theta);
                0          1  0;
                sin(theta) 0  cos(theta)];

Rmz = @(theta) [cos(theta) -sin(theta) 0;
                sin(theta)  cos(theta) 0;
                0           0          1];
                        
V134 = (Rmz(2*pi/3)*V123')';
V142 = (Rmz(2*pi/3)*V134')';
V234 = (Rmy(-acos(-1/3))*Rmz(pi/3)*V142')';
            
V = [V123; V134; V142; V234];

% Triplet indices list 
T = [T;
     T+repmat(size(V123,1),   [size(T,1) size(T,2)]);...
     T+2*repmat(size(V123,1), [size(T,1) size(T,2)]);...
     T+3*repmat(size(V123,1), [size(T,1) size(T,2)])];
    
TRI = triangulation(T,V(:,1),V(:,2),V(:,3));

%  Display
if option_display
    
    figure;    
    trimesh(TRI), hold on;
    colormap([0 0 1]);
    axis square, axis equal, axis tight;
    view(-52,16);
    
end


end % mesh_reuleaux_tetrahedron


%% sample_and_curve_triangle subfunction
function [T, I] = sample_and_curve_triangle(V0, V1, V2, nbstep, warp)
%
% Authors : nicolas.douillet (at) free.fr, 2017-2024.
%           Gerd Wachsmuth,                     2021.


% Create sampling grid
Ndim = size(V0,1);

% (V0V1, V0V2) base
u = (V1 - V0);
v = (V2 - V0);

T = zeros((nbstep+1)*(nbstep+2)/2, Ndim);
    
k = 1;

% Sampling & vertices generation    
for m = 0:nbstep
    
    for n = 0:nbstep
        
        if (m+n) <= nbstep % in (V0,V1,V2) triangle conditions ; indices # nb segments
            
            % Barycentric coordinates.
            l1 = m/nbstep;
            l2 = n/nbstep;
            l3 = (nbstep - n - m)/nbstep;

            % Transform the barycentric coordinates.
            b1 = l1^warp;
            b2 = l2^warp;
            b3 = l3^warp;

            % Assure that they still sum up to 1.
            db = (b1 + b2 + b3) - 1;
            b1 = b1 - db*l1;
            b2 = b2 - db*l2;
            b3 = b3 - db*l3;

            % translation vector
            tv = b1*u + b2*v;
            T(k,:) = (V0 + tv)';
            k = k+1;
            
        end
        
    end
    
end
    
% Index triplets list construction
I = zeros(nbstep^2,3);
row_length = 1 + nbstep;
cum_row_length = row_length;
row_idx = 1;
p = 1;

while p <= nbstep^2 && row_length > 1
    
     i = p;
    
    if p < 2 % "right" triangle serie only
        
        while i < cum_row_length
            
            I(row_idx,:) = [i i+1 i+row_length];
            row_idx = row_idx + 1;
            i = i +1;
            
        end
        
        row_length = row_length - 1;
        cum_row_length = cum_row_length + row_length;
        p = p + row_length+1;
        
    else
        
        % Since p >= 2
        while i < cum_row_length % both triangle series
            
            I(row_idx,:) = [i i+1 i+row_length];
            row_idx = row_idx + 1;            
            I(row_idx,:) = [i i-row_length i+1]; % + upside-down triangles serie
            row_idx = row_idx + 1;
            
            i = i +1;
        end
        
        row_length = row_length - 1;
        cum_row_length = cum_row_length + row_length;
        p = p + row_length+1;
        
    end
    
end

I = sort(I, 2);
I = unique(I, 'rows');


end % sample_and_curve_triangle


%% inflate_triangle_sample_from_opposite_vertex subfunction
function V = inflate_triangle_sample_from_opposite_vertex(U, X, Rho)
%
% Authors : nicolas.douillet (at) free.fr, 2017-2024.
%           Gerd Wachsmuth,                     2021.


% We are looking for t such that
%   || t U - X ||^2 = Rho^2
% This is a quadratic equation.

% Discriminant
D = sum(U.*X, 2).^2 - sum(U.^2,2).*(sum(X.^2,2) - Rho^2);

% We take the positive solution
t = (sum(U.*X, 2) + sqrt(D)) ./ sum(U.^2,2);

V = t.*U;


end % inflate_triangle_sample_from_opposite_vertex