function varargout = human_interface(varargin)
% HUMAN_INTERFACE MATLAB code for human_interface.fig
%      HUMAN_INTERFACE, by itself, creates a new HUMAN_INTERFACE or raises the existing
%      singleton*.
%
%      H = HUMAN_INTERFACE returns the handle to a new HUMAN_INTERFACE or the handle to
%      the existing singleton*.
%
%      HUMAN_INTERFACE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in HUMAN_INTERFACE.M with the given input arguments.
%
%      HUMAN_INTERFACE('Property','Value',...) creates a new HUMAN_INTERFACE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before human_interface_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to human_interface_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help human_interface

% Last Modified by GUIDE v2.5 17-Feb-2016 15:51:23

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @human_interface_OpeningFcn, ...
                   'gui_OutputFcn',  @human_interface_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before human_interface is made visible.
function human_interface_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to human_interface (see VARARGIN)

% Choose default command line output for human_interface
handles.output = hObject;
handles.imageLabels =[];
handles.currentImage =0;
% Update handles structure
guidata(hObject, handles);
% UIWAIT makes human_interface wait for user response (see UIRESUME)
% uiwait(handles.figure1);

%----- Display Image to the human agent.
function displayImages(handles,label,images, agent)
persistent mImages currentImage imageLabels mAgent
if(nargin==4)
    mImages=images;
    currentImage = handles.currentImage;
    imageLabels=[];
    mAgent = agent;
else
    imageLabels(currentImage) = label;
end
if(currentImage == length(mImages)) 
    sendImageLabels(mAgent,imageLabels);
else
    currentImage = currentImage + 1;
    imshow(mImages{currentImage},'Parent',handles.axes1);
end


% --- Outputs from this function are returned to the command line.
function varargout = human_interface_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
varargout{2} = handles;


% --- Executes on button press in class1button.
function class1button_Callback(hObject, eventdata, handles)
% hObject    handle to class1button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
displayImages(handles,1);

% --- Executes on button press in class2button.
function class2button_Callback(hObject, eventdata, handles)
% hObject    handle to class2button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
displayImages(handles,-1);


