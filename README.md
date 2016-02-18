# ILS - Image Labeling System
Image Labeling System

To run:
1. Open a MATLAB terminal for the local server.
2. Open a MATLAB terminal for each remote agent.
3. Initialize experiment environment by creating an environment,
    "E = Experiment(imageDatabasePath,data,labels);"
4. Initialize agents in each MATLAB terminal.
5. For Human agents:
    "H = Human(imageDatabasePath,port);"
6. For Computer-Vision agents:
7.  "CV = ComputerVision(imageDatabasePath,port);"
5. Begin experiment, "startExperiment(E);"

## Dependencies

This code has been written using Matlab 2014a and later and has not been tested using earlier versions. Additionally, you must have access to matlab's image processing toolbox, optimization toolbox and instrument control toolbox. 

This code requires the MatConvNet and LibSVM software packages.

MatConvNet is a deep-learning framework for matlab. It can be downloaded and installed here:
(http://www.vlfeat.org/matconvnet/install/)

LibSVM is a support vector machine library that contains mexfiles for building SVMs in matlab. LibSVM can be downloaded from here:
(https://www.csie.ntu.edu.tw/~cjlin/libsvm/)



