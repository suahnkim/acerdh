function main

%Example code
original_image_name='image/original/Bike_grayscaled.png';
acerdh_image_name='image/acerdh_enhanced/Bike_grayscaled_acerdh.png';
payload_length=25000; %number of bits to be embedded

%Read image and convert it to double
original_image = imread(original_image_name);

%random payload
rng(0) %set randomness
payload=randi([0,1],payload_length,1);

%Embedding 
[acerdh_image, ~, ~, ~,embedding_capacity_left]=acerdh_splitting(original_image,payload);
if embedding_capacity_left < 0
    disp('Failed embedding')
else
    disp(['Can embed ' num2str(embedding_capacity_left) ' bits more (estimated)'])
end

%save the acerdh_image
imwrite(uint8(acerdh_image),acerdh_image_name);
        
%Recovery
%read the acerdh_image
acerdh_image_read = imread(acerdh_image_name);

[recovered_image, recovered_payload]=acerdh_splitting_recovery(acerdh_image_read);



%Image check
if isequal(recovered_image,original_image)
    disp('Original image recovered successfully')
    if isequal(recovered_payload,payload)
        disp('Payload recovered successfully')
        %Show images
        figure(1)
        imshow(uint8(original_image))
        figure(2)
        imshow(uint8(acerdh_image_read))
    else
        disp('Failed to recover the payload')
    end
else
    disp('Failed to recover the original image')
    if isequal(recovered_payload,payload)
        disp('Payload recovered')
    else
        disp('Failed to recover the payload')
    end
end



