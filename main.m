function main

%Example code
image = rgb2gray(imread('images/Bike.png'));


%Payload
rng(0) %set randomness
payload_length=25000; %number of bits to be embedded
payload=randi([0,1],payload_length,1);

%Embedding 
[rdh_image, ~, ~, ~,embedding_capacity_left]=acerdh_splitting(image,payload);
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