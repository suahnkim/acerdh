function [rdh_image, iteration_max, EC_list, LM_size_list,embedding_capacy_left]=acerdh_splitting(image,actual_payload,iteration_max)
%Preprocess Payload (length appended)
image_size=size(image);
payload_length_max=2*ceil(log2(image_size(1)*image_size(2)+1));
actual_payload=[de2bi(length(actual_payload),payload_length_max)'; actual_payload];


switch nargin
    case 2
        iteration_max = 1000;
end
rng(0);
%image = image(5:end-5,5:end-5);
image_size = size(image);
splitting_distortion=zeros(1,iteration_max);
combining_distortion=zeros(1,iteration_max);
P_H_list=zeros(1,iteration_max);
P_L_list=zeros(1,iteration_max);
EC_list=zeros(1,iteration_max);
LM_size_list=zeros(1,iteration_max);
ref_image_hor = zeros(image_size(1)*image_size(2),iteration_max);
ref_image_hor(:,1) = reshape(image,image_size(1)*image_size(2),1);

image_hor=ref_image_hor(:,1);
P_H=0;
P_L=0;
iteration=0;
tic
payload_total=[];

while true
    %Adaptive peak selection
    P_H_previous=P_H;
    P_L_previous=P_L;
    [P_H, P_L]=peak_selection(image_hor);
    
    %Direction of histogram shifting
    if P_H < P_L %RHS
        d = 1;
    else %LHS
        d = -1;
    end
    
    %Record location map
    LM=double(image_hor(image_hor==P_L | image_hor==P_L-d)==P_L-d);
    
    %Embedding capacity + stop condition check
    H_P_H=sum(image_hor==P_H);
    
    if H_P_H-sum(image_hor(1:16)==P_H) < length(LM)+32 || iteration == iteration_max %Stop condition reached
        %no need to update iteration
        P_H=P_H_previous;
        P_L=P_L_previous;
        P_H_previous=P_H_list(iteration);
        P_L_previous=P_L_list(iteration);
        first_16_pixels=ref_image_hor(1:16,iteration);
        original_16_lsb=mod(first_16_pixels,2);
        
        if P_H < P_L %RHS
            d = 1;
        else %LHS
            d = -1;
        end
        
        
        %Exclude first 16 pixels from histogram shifting
        image_hor = ref_image_hor(17:end,iteration);
        H_P_H=sum(image_hor==P_H);
        LM=(image_hor(image_hor==P_L | image_hor==P_L-d)==P_L-d);
        
        payload_total(end-payload_length_last+1:end)=[];
        if length(payload_total) < length(actual_payload)
            payload_left_over=length(actual_payload)-length(payload_total);
            if payload_left_over < H_P_H-length(LM)-32
                synthetic_payload =randi([0,1],payload_left_over);
                payload = [actual_payload(length(payload_total)+1:end) synthetic_payload];
            else
                payload = actual_payload(length(payload_total)+1:length(payload_total)+H_P_H-length(LM)-32);
            end
        else
            payload =randi([0,1],H_P_H-length(LM)-32,1);
        end
        
        message=[LM ; de2bi(P_H_previous,8)'; de2bi(P_L_previous,8)';original_16_lsb;payload];
        EC_list(iteration)=H_P_H-length(LM)-32;
        LM_size_list(iteration)=length(LM);
        message_whole=zeros(length(image_hor),1);
        message_whole(image_hor==P_H)=message;
        combining_distortion(iteration)=sum(image_hor==P_L-d);
        %Combine P_L with its neighbor
        image_hor(image_hor==P_L-d)=image_hor(image_hor==P_L-d)+d;
        
        %Shift P_H's neighbors towards P_L
        if d == 1
            image_hor(image_hor > P_H & image_hor < P_L)=image_hor(image_hor > P_H & image_hor < P_L)+d; %RHS
        else
            image_hor(image_hor < P_H & image_hor > P_L)=image_hor(image_hor < P_H & image_hor > P_L)+d; %LHS
        end
        %Embed P_H
        image_hor(image_hor==P_H & message_whole)=image_hor(image_hor==P_H & message_whole)+d;
        splitting_distortion(iteration)=sum(image_hor==P_H+d);
        %Append back the first 16 pixels and replace 16 lsbs with P_H and P_L
        image_hor=[bitxor(bitxor(first_16_pixels,mod(first_16_pixels,2)),[de2bi(P_H,8)'; de2bi(P_L,8)']) ;image_hor];
        iteration_max = iteration;
        rdh_image=reshape(image_hor,image_size(1),image_size(2));
        
        EC_list(iteration+1:end)=[];
        LM_size_list(iteration+1:end)=[];
        ref_image_hor(:,iteration+1:end) = [];
        splitting_distortion(iteration+1:end)=[];
        combining_distortion(iteration+1:end)=[];
        embedding_capacy_left=length(payload_total)-length(actual_payload);
        break
        
    else
        
        if length(payload_total) < length(actual_payload)
            payload_left_over=length(actual_payload)-length(payload_total);
            if payload_left_over < H_P_H-length(LM)-16
                synthetic_payload =randi([0,1],H_P_H-length(LM)-16-payload_left_over,1);
                payload = [actual_payload(length(payload_total)+1:end); synthetic_payload];
            else
                payload = actual_payload(length(payload_total)+1:length(payload_total)+H_P_H-length(LM)-16);
            end
        else
            payload =randi([0,1],H_P_H-length(LM)-16,1);
        end
        
        payload_length_last=length(payload);
        payload_total=[payload_total; payload];
        message=[LM ; de2bi(P_H_previous,8)'; de2bi(P_L_previous,8)';payload];
        iteration=iteration+1;
        EC_list(iteration)=H_P_H-length(LM)-16;
        LM_size_list(iteration)=length(LM);
        
        ref_image_hor(:,iteration)=image_hor;
        P_H_list(iteration)=P_H_previous;
        P_L_list(iteration)=P_L_previous;
    end
    message_whole=zeros(length(image_hor),1);
    message_whole(image_hor==P_H)=message;
    
    combining_distortion(iteration)=sum(image_hor==P_L-d);
    %Combine P_L with its neighbor
    image_hor(image_hor==P_L-d)=image_hor(image_hor==P_L-d)+d;
    
    %Shift P_H's neighbors towards P_L
    if d == 1
        image_hor(image_hor > P_H & image_hor < P_L)=image_hor(image_hor > P_H & image_hor < P_L)+d; %RHS
    else
        image_hor(image_hor < P_H & image_hor > P_L)=image_hor(image_hor < P_H & image_hor > P_L)+d; %LHS
    end
    %Embed P_H
    image_hor(image_hor==P_H & message_whole)=image_hor(image_hor==P_H & message_whole)+d;
    splitting_distortion(iteration)=sum(image_hor==P_H+d);
end

disp("Encoding time")
toc
% figure(1);imshow(uint8(image));figure(2);imshow(uint8(reshape(ref_image_hor(:,end),image_size(1),image_size(2))))
% figure(3);histogram(image,256);figure(4);histogram(ref_image_hor(:,iteration),256)

end

function P_L=find_P_L(table,P_H)
combine_table = [table(1:end-1,1)+table(2:end,1) table(1:end-1,2)];

%sort
[sort_combine_table, sort_combine_table_index]=sort(combine_table(:,1));
sort_combine_table = [sort_combine_table combine_table(sort_combine_table_index,2)];
list_P_L=sort_combine_table(sort_combine_table(:,1)==sort_combine_table(1,1),:);

%Update list_P_L based on RHS, since for RHS case P_L combines w P_L+1
list_P_L(list_P_L(:,2)>P_H,1)=list_P_L(list_P_L(:,2)>P_H,1)+1;

%if there are multiple candidates, choose the one with less P_L-d
list_P_L_d=[list_P_L(:,2) table(list_P_L(:,2)+1,1)];
list_P_L=list_P_L(list_P_L_d(:,2)==max(list_P_L_d(:,2)),:);
%if there are multiple candidates, choose the one that is furthest away
%from P_H
[~,index]=min(abs(list_P_L(:,2)-P_H));
P_L=list_P_L(index,2);
end

function [P_H, P_L]=peak_selection(image_hor)
table = [ zeros(256,1) transpose(0:255)];

for i=1:length(image_hor)
    table(image_hor(i)+1)=table(image_hor(i)+1)+1;
end
[~,index]=max(table(:,1));
P_H=table(index,2);
P_L=find_P_L(table,P_H);
end
