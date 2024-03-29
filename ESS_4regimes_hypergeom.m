numworkers=str2num(getenv('PROCS')); %#ok<ST2NM>
dellacluster=parcluster('local');
dellacluster.JobStorageLocation=strcat('/scratch/network/brush/tmp/',getenv('SLURM_JOB_ID'));
dellapool=parpool(dellacluster, numworkers) ;

numsigs_permove=str2num(getenv('numsigs')); %#ok<ST2NM>
nummoves=str2num(getenv('nummoves'));%#ok<ST2NM>

N=20;
b=1;

strats_hyper=1:1:(N-1);
L=length(strats_hyper);

Tvals_hyper=[1]; %#ok<NBRAK>
Nt=length(Tvals_hyper);

radvals_hyper=[0:.02:.1 .2:.1:1.1]; 
% radvals=.1;
Nr=length(radvals_hyper);

ESSseaten_hyper=cell(Nt,Nr);
ESSsgettoeat_hyper=cell(Nt,Nr);
ESSsboth_hyper=cell(Nt,Nr);
ESSsgenerous_hyper=cell(Nt,Nr);

storefitnesseaten_hyper=cell(Nt,Nr);
storerhoeaten_hyper=cell(Nt,Nr);

storefitnessgettoeat_hyper=cell(Nt,Nr);
storerhogettoeat_hyper=cell(Nt,Nr);

storefitnessboth_hyper=cell(Nt,Nr);
storerhoboth_hyper=cell(Nt,Nr);

storefitnessgenerous_hyper=cell(Nt,Nr);
storerhogenerous_hyper=cell(Nt,Nr);

t0=tic;

for q=1:Nt
    for p=1:Nr
        T=Tvals_hyper(q);
        radius=radvals_hyper(p);

        fitnesseaten=zeros(L,L);
        rhoeaten=zeros(L,L);

        fitnessgettoeat=zeros(L,L);
        rhogettoeat=zeros(L,L);
        
        fitnessboth=zeros(L,L);
        rhoboth=zeros(L,L);
        
        fitnessgenerous=zeros(L,L);
        rhogenerous=zeros(L,L);

        featen=zeros(L,L,N-1);
        geaten=zeros(L,L,N-1);

        fgettoeat=zeros(L,L,N-1);
        ggettoeat=zeros(L,L,N-1);
        
        fboth=zeros(L,L,N-1);
        gboth=zeros(L,L,N-1);
        
        fgenerous=zeros(L,L,N-1);
        ggenerous=zeros(L,L,N-1);
        
        parfor ind=1:(L*L*(N-1))
%         parfor ind=1:5
            [u,v,k]=ind2sub([L,L,N-1],ind);
            % rows are residents, columns are invaders, transpose to plot
            % normally
            resident=strats_hyper(u); %#ok<PFBNS>
            invader=strats_hyper(v);

            strategy=resident*ones(1,N);
            strategy(N+1-(1:k))=invader;
            [probeaten, probgettoeat, both, generous]=signalingevents_4regimes_parallel_hypergeom(strategy,numsigs_permove,nummoves,radius,b,T);

            perfeaten=1-probeaten;
            featen(ind)=mean(perfeaten(N+1-(1:k)));
            geaten(ind)=mean(perfeaten(N+1-((k+1):N)));

            perfgettoeat=probgettoeat;
            fgettoeat(ind)=mean(perfgettoeat(N+1-(1:k)));
            ggettoeat(ind)=mean(perfgettoeat(N+1-((k+1):N)));
            
            perfboth=both;
            fboth(ind)=mean(perfboth(N+1-(1:k)));
            gboth(ind)=mean(perfboth(N+1-((k+1):N)));
            
            perfgenerous=generous;
            fgenerous(ind)=mean(perfgenerous(N+1-(1:k)));
            ggenerous(ind)=mean(perfgenerous(N+1-((k+1):N)));

        end


        for ind=1:L*L
            [u,v]=ind2sub([L,L],ind);
            where=zeros(N-1,1);
            for k=1:N-1
                where(k)=sub2ind([L,L,N-1],u,v,k);
            end
            featen_now=featen(where);
            geaten_now=geaten(where);

            fgettoeat_now=fgettoeat(where);
            ggettoeat_now=ggettoeat(where);
            
            fboth_now=fboth(where);
            gboth_now=gboth(where);
            
            fgenerous_now=fgenerous(where);
            ggenerous_now=ggenerous(where);

            fitnesseaten(ind)=featen_now(1)/geaten_now(1);
            fitnessgettoeat(ind)=fgettoeat_now(1)/ggettoeat_now(1);
            fitnessboth(ind)=fboth_now(1)/gboth_now(1);
            fitnessgenerous(ind)=fgenerous_now(1)/ggenerous_now(1);

            ratio=geaten_now./featen_now;
            tosum=ones(1,N-1);
            for k=1:(N-1)
                tosum(k)=prod(ratio(1:k));
            end
            rhoeaten(ind)=1/(1+sum(tosum));

            ratio=ggettoeat_now./fgettoeat_now;
            tosum=ones(1,N-1);
            for k=1:(N-1)
                tosum(k)=prod(ratio(1:k));
            end
            rhogettoeat(ind)=1/(1+sum(tosum));
            
            ratio=gboth_now./fboth_now;
            tosum=ones(1,N-1);
            for k=1:(N-1)
                tosum(k)=prod(ratio(1:k));
            end
            rhoboth(ind)=1/(1+sum(tosum));
            
            ratio=ggenerous_now./fgenerous_now;
            tosum=ones(1,N-1);
            for k=1:(N-1)
                tosum(k)=prod(ratio(1:k));
            end
            rhogenerous(ind)=1/(1+sum(tosum));
        end  
        
        storefitnesseaten_hyper{q,p}=fitnesseaten;
        storerhoeaten_hyper{q,p}=rhoeaten;
        
        storefitnessgettoeat_hyper{q,p}=fitnessgettoeat;
        storerhogettoeat_hyper{q,p}=rhogettoeat;
        
        storefitnessboth_hyper{q,p}=fitnessboth;
        storerhoboth_hyper{q,p}=rhoboth;
        
        storefitnessgenerous_hyper{q,p}=fitnessgenerous;
        storerhogenerous_hyper{q,p}=rhogenerous;

        eqstratseaten=eq_strats(N,fitnesseaten,rhoeaten);
        ESSseaten_hyper{q,p}=eqstratseaten{2};

        eqstratsgettoeat=eq_strats(N,fitnessgettoeat,rhogettoeat);
        ESSsgettoeat_hyper{q,p}=eqstratsgettoeat{2};
        
        eqstratsboth=eq_strats(N,fitnessboth,rhoboth);
        ESSsboth_hyper{q,p}=eqstratsboth{2};
        
        eqstratsgenerous=eq_strats(N,fitnessgenerous,rhogenerous);
        ESSsgenerous_hyper{q,p}=eqstratsgenerous{2};
    end
end

t=toc(t0);
disp(t);

filename=strcat('/home/brush/schooling_consensus/ESS_4regimes_hypogeom','_nummoves=',num2str(nummoves),'_numpermove=',num2str(numsigs_permove),'.mat');
save(filename,'strats_hyper','radvals_hyper','Tvals_hyper','storefitnesseaten_hyper','storerhoeaten_hyper','ESSseaten_hyper','storefitnessgettoeat_hyper','storerhogettoeat_hyper','ESSsgettoeat_hyper','storefitnessboth_hyper','storerhoboth_hyper','ESSsboth_hyper','storefitnessgenerous_hyper','storerhogenerous_hyper','ESSsgenerous_hyper');

delete(dellapool);

exit ;
