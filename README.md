# ILS
Image Labeling System

To run:
1. Open a MATLAB terminal for the local server.
2. Open a MATLAB terminal for each remote agent.
3. Initialize experiment environment by creating an environment,
    "E = Experiment(data,labels);"
4. Initialize agents in each MATLAB terminal,
    "A = RemoteAgent('human',port);"
5. Begin experiment, "startExperiment(E);"
