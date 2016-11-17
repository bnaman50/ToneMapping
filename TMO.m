function compTime = myTMO( img, lam, alphaWls, lamWls  )
%
%       [ imgOut, compTime ] = myTMO( img, lam, alpha, lambda )  
%
%
%        Input:
%           -img:  3-channel input HDR image
%           -lam: tradeoff- term (between 1 and 2)
%                   Default is 1
%           -alphaWls, lamWls: parameters of Wls filter
%
%        Output:
%           -writes the output image to your working directory
%           -compTime: computation time
% 

tic; 
if( ~exist( 'lam', 'var' ) ),
    lam = 1;
end

if( ~exist( 'lamWls', 'var' ) ),
    lamWls = 20;
end

if( ~exist( 'alphaWls', 'var' ) ),
    alphaWls = 1.2;
end

%% Convert input HDR image to greyscale
I = 0.2126*img( :, :, 1 ) + 0.7152*img( :, :, 2 ) + 0.0722*img( :, :, 3 );
logI = log( I + eps );

%% Perform edge-preserving smoothing using WLS
base = log( wlsFilter( I, lamWls, alphaWls ) );
detail = logI - base;

%% Iterative Process
hgamma = vision.GammaCorrector( 2.2, 'Correction', 'De-gamma' ); 
initImg = step( hgamma, img );
initImg = 0.2126*initImg( :, :, 1 ) + 0.7152*initImg( :, :, 2 ) + 0.0722*initImg( :, :, 3 );
initImg = log( initImg + eps );

A = logI./( base.*max( base(:) ) );
u = ( A + lam*initImg )/( 1 + lam );

disp('No. of iterations')
i = 1 
err_mat = zeros(1, 1000); % Assuming that the process will converge after 1000 iterations

while 1
    I_Edge = log( wlsFilter( u, lamWls, alphaWls ) );
    A = logI./( ( I_Edge ).*max( I_Edge(:) ) );
    
    u_old = u;
    u = ( A + lam*u )/( 1 + lam );
    error = u - u_old;
    error = rms( error(:) );
    err_mat( 1, i ) = error;
    i = i + 1
    %err_mat(end+1)=error;
    if error < 0.3
        break
    end
end


OUT = u + detail ;
OUT = exp( OUT );

%% Restore color
OUT = OUT./I;
OUT = img .* padarray( OUT, [ 0, 0, 2 ], 'circular' , 'post' );

%% Finally, shift, scale, and gamma correct the result
gamma = 1.0/2.2;
bias = -min( OUT(:) );
gain = 0.45;

OUT = ( gain*( OUT + bias ) ).^gamma;
imwrite(abs(OUT),'memorial_newTest.jpg')

compTime = toc;

end