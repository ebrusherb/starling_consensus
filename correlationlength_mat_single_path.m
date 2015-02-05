function [pathbins,avgcorr,corrlength] = correlationlength_mat_single_path(M,d,b,radius,receiver)

Mbin=M;
Mbin(M==-1)=0;
Mbin(~~M)=1;
g=sparse(Mbin);
paths=graphallshortestpaths(g);

N=size(M,2);
corrvec=[];
pathvec=[];
% for i=1:N
%     receiver=i;
    allreceivers=d(receiver,:)<=radius;
    beta=zeros(N,1);
    beta(allreceivers)=1;
    bbeta=b*beta;
    im=1;
    while im>0
        corrs=paircorrelations(M,bbeta);
        im=max(max(abs(imag(corrs))));
    end
    uppercorr=triu(corrs,1);
    upperpath=triu(paths,1);
    lowerpath=triu(transpose(paths),1);
    corrvectoadd=uppercorr(~~uppercorr);
    pathvectoadd=[upperpath(~~upperpath) lowerpath(~~lowerpath)];
    pathvectoadd=min(pathvectoadd,[],2);
    corrvec=[corrvec; corrvectoadd; diag(corrs)]; 
    pathvec=[pathvec; pathvectoadd; diag(paths)]; 
% end
pathbins=0:1:max(max(paths));

[~,w]=histc(pathvec,pathbins);
l=length(pathbins);
avgcorr=zeros(1,l);
for i=1:l
    now=(w==i);
    avgcorr(i)=mean(corrvec(now));
end
i=sum(avgcorr>=0);
if i<l
    f=find(avgcorr<0,1,'first');
%     corrlength=avgcorr(i)/(avgcorr(i)-avgcorr(i+1))*(distbins(i+1)-distbins(i))+distbins(i);
    corrlength=interp1q(avgcorr(f:-1:(f-1))',pathbins(f:-1:(f-1))',0); 
else corrlength=max(pathvec);
end

end