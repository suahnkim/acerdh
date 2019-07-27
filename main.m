function main

%Example code
image = rgb2gray(imread('msl01.png'));
image_size=size(image);

%Payload
payload_length=25000; %number of bits to be embedded
payload=randi([0,1],payload_length,1);
%Preprocess Payload (length appended)
payload_length_max=2*ceil(log2(image_size(1)*image_size(2)+1));
adjusted_payload=[de2bi(payload_length,payload_length_max)'; payload];

%Embedding 
[rdh_image, ~, ~, ~,embedding_capacity_left]=acerdh_splitting(image,adjusted_payload);
if embedding_capacity_left < 0
    disp('Failed embedding')
else
    disp(['Can embed ' num2str(embedding_capacity_left) ' bits more (estimated)'])
end

%Recovery
[re_image, payload_rec]=acerdh_splitting_recovery(rdh_image);



%Image check
if isequal(re_image,image)
    disp('Original image recovered')
else
    disp('Failed to recover the original image')
end

if isequal(payload_rec,payload)
    disp('Payload recovered')
else
    disp('Failed to recover the payload')
end

%Show images
figure(1)
imshow(uint8(image))
figure(2)
imshow(uint8(rdh_image))