# ILS - Image Labeling System
To run: <br />
1. Open a MATLAB terminal for the local server. <br />
2. Open a MATLAB terminal for each remote agent. <br />
3. Initialize experiment environment by creating an environment: <br />
..* "E = Experiment(imageDatabasePath,data,labels);" <br />
4. Initialize agents in each MATLAB terminal. <br />
..* For Human agents: "H = Human(imageDatabasePath,port);" <br />
..* For Computer-Vision agents: "CV = ComputerVision(imageDatabasePath,port);" <br />
5. Begin experiment, "startExperiment(E);" <br />

## Dependencies
This code has been written using Matlab 2014a and later and has not been tested using earlier versions. Additionally, you must have access to matlab's image processing toolbox, optimization toolbox and instrument control toolbox. 

This code requires the MatConvNet and LibSVM software packages.

MatConvNet is a deep-learning framework for matlab. It can be downloaded and installed from the [MatConvNet webpage](http://www.vlfeat.org/matconvnet/install/)

LibSVM is a support vector machine library that contains mexfiles for building SVMs in matlab. LibSVM can be downloaded from the [LibSVM webpate](https://www.csie.ntu.edu.tw/~cjlin/libsvm/)



