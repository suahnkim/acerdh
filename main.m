function main
%Example code
image = rgb2gray(imread('msl01.png'));
acerdh_image=ACERDH(image);

figure(1)
imshow(uint8(image))
figure(2)
imshow(uint8(acerdh_image))