function [ tocFiles ] = getFilesByToc( file, docFiles )
%GETFILESBYTOC Summary of this function goes here
%   Detailed explanation goes here

tocFiles = [];
if hasTocFile(file)
  tocFiles = getFilesByName(docFiles,readTocFile(file));
end